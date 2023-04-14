import { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { assertProps } from 'helpers/assert_props';
import StatusIcon from '~/vue_merge_request_widget/components/extensions/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import WidgetContentRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import * as logger from '~/lib/logger';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/vue_merge_request_widget/components/extensions/telemetry', () => ({
  createTelemetryHub: jest.fn().mockReturnValue({
    viewed: jest.fn(),
    expanded: jest.fn(),
    fullReportClicked: jest.fn(),
  }),
}));

describe('~/vue_merge_request_widget/components/widget/widget.vue', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponent(StatusIcon);
  const findExpandedSection = () => wrapper.findByTestId('widget-extension-collapsed-section');
  const findActionButtons = () => wrapper.findComponent(ActionButtons);
  const findToggleButton = () => wrapper.findByTestId('toggle-button');
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findDynamicScroller = () => wrapper.findByTestId('dynamic-content-scroller');

  const createComponent = ({ propsData, slots, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(Widget, {
      propsData: {
        isCollapsible: false,
        loadingText: 'Loading widget',
        widgetName: 'WidgetTest',
        fetchCollapsedData: () => Promise.resolve({ headers: {}, status: HTTP_STATUS_OK }),
        value: {
          collapsed: null,
          expanded: null,
        },
        ...propsData,
      },
      slots,
      stubs: {
        StatusIcon,
        ActionButtons,
        ContentRow: WidgetContentRow,
      },
    });
  };

  describe('on mount', () => {
    it('fetches collapsed', async () => {
      const fetchCollapsedData = jest
        .fn()
        .mockReturnValue(Promise.resolve({ headers: {}, status: HTTP_STATUS_OK, data: {} }));

      createComponent({ propsData: { fetchCollapsedData } });
      await waitForPromises();
      expect(fetchCollapsedData).toHaveBeenCalled();
      expect(wrapper.vm.summaryError).toBe(null);
    });

    it('sets the error text when fetch method fails', async () => {
      createComponent({
        propsData: { fetchCollapsedData: jest.fn().mockRejectedValue('Something went wrong') },
      });
      await waitForPromises();
      expect(wrapper.findByText('Failed to load').exists()).toBe(true);
      expect(findStatusIcon().props()).toMatchObject({ iconName: 'failed', isLoading: false });
    });

    it('displays the error text when :has-error is true', () => {
      createComponent({
        propsData: { hasError: true, errorText: 'API error' },
      });
      expect(wrapper.findByText('API error').exists()).toBe(true);
    });

    it('displays loading icon until request is made and then displays status icon when the request is complete', async () => {
      const fetchCollapsedData = jest
        .fn()
        .mockReturnValue(Promise.resolve({ headers: {}, status: HTTP_STATUS_OK, data: {} }));

      createComponent({ propsData: { fetchCollapsedData, statusIconName: 'warning' } });

      // Let on mount be called
      await nextTick();

      expect(findStatusIcon().props('isLoading')).toBe(true);

      // Wait until `fetchCollapsedData` is resolved
      await waitForPromises();

      expect(findStatusIcon().props('isLoading')).toBe(false);
      expect(findStatusIcon().props('iconName')).toBe('warning');
    });

    it('displays the loading text', async () => {
      createComponent({
        propsData: {
          statusIconName: 'warning',
        },
      });

      expect(wrapper.text()).not.toContain('Loading');
      await nextTick();
      expect(wrapper.text()).toContain('Loading');
    });

    it('validates widget name', () => {
      expect(() => {
        assertProps(Widget, { widgetName: 'InvalidWidgetName' });
      }).toThrow();
    });
  });

  describe('fetch', () => {
    it('sets the data.collapsed property after a successfull call - multiPolling: false', async () => {
      const mockData = { headers: {}, status: HTTP_STATUS_OK, data: { vulnerabilities: [] } };
      createComponent({ propsData: { fetchCollapsedData: () => Promise.resolve(mockData) } });
      await waitForPromises();
      expect(wrapper.emitted('input')[0][0]).toEqual({ collapsed: mockData.data, expanded: null });
    });

    it('sets the data.collapsed property after a successfull call - multiPolling: true', async () => {
      const mockData1 = {
        headers: {},
        status: HTTP_STATUS_OK,
        data: { vulnerabilities: [{ vuln: 1 }] },
      };
      const mockData2 = {
        headers: {},
        status: HTTP_STATUS_OK,
        data: { vulnerabilities: [{ vuln: 2 }] },
      };

      createComponent({
        propsData: {
          multiPolling: true,
          fetchCollapsedData: () => [
            () => Promise.resolve(mockData1),
            () => Promise.resolve(mockData2),
          ],
        },
      });

      await waitForPromises();

      expect(wrapper.emitted('input')[0][0]).toEqual({
        collapsed: [mockData1.data, mockData2.data],
        expanded: null,
      });
    });

    it('throws an error when the handler does not include headers or status objects', async () => {
      const error = new Error(Widget.MISSING_RESPONSE_HEADERS);
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      jest.spyOn(logger, 'logError').mockImplementation();
      createComponent({
        propsData: {
          fetchCollapsedData: () => Promise.resolve({}),
        },
      });
      await waitForPromises();
      expect(wrapper.emitted('input')).toBeUndefined();
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
      expect(logger.logError).toHaveBeenCalledWith(error.message);
    });

    it('calls sentry when failed', async () => {
      const error = new Error('Something went wrong');
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      createComponent({
        propsData: {
          fetchCollapsedData: () => Promise.reject(error),
        },
      });
      await waitForPromises();
      expect(wrapper.emitted('input')).toBeUndefined();
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('content', () => {
    it('displays summary property when summary slot is not provided', () => {
      createComponent({
        propsData: {
          summary: 'Hello world',
        },
      });

      expect(wrapper.findByTestId('widget-extension-top-level-summary').text()).toBe('Hello world');
    });

    it.todo('displays content property when content slot is not provided');

    it('displays the summary slot when provided', async () => {
      createComponent({
        slots: {
          summary: '<b>More complex summary</b>',
        },
      });

      await waitForPromises();

      expect(wrapper.findByTestId('widget-extension-top-level-summary').text()).toBe(
        'More complex summary',
      );
    });

    it('does not display action buttons if actionButtons is not provided', () => {
      createComponent();
      expect(findActionButtons().exists()).toBe(false);
    });

    it('does display action buttons if actionButtons is provided', () => {
      const actionButtons = [{ text: 'click-me', href: '#' }];

      createComponent({
        propsData: {
          actionButtons,
        },
      });

      expect(findActionButtons().props('tertiaryButtons')).toEqual(actionButtons);
    });
  });

  describe('help popover', () => {
    it('renders a help popover', () => {
      createComponent({
        propsData: {
          helpPopover: {
            options: { title: 'My help popover title' },
            content: { text: 'Help popover content', learnMorePath: '/path/to/docs' },
          },
        },
      });

      const popover = findHelpPopover();

      expect(popover.props('options')).toEqual({ title: 'My help popover title' });
      expect(popover.props('icon')).toBe('information-o');
      expect(wrapper.findByText('Help popover content').exists()).toBe(true);
      expect(wrapper.findByText('Learn more').attributes('href')).toBe('/path/to/docs');
      expect(wrapper.findByText('Learn more').attributes('target')).toBe('_blank');
    });

    it('does not render help popover when it is not provided', () => {
      createComponent();
      expect(findHelpPopover().exists()).toBe(false);
    });
  });

  describe('handle collapse toggle', () => {
    it('displays the toggle button correctly', () => {
      createComponent({
        propsData: {
          isCollapsible: true,
        },
        slots: {
          content: '<b>More complex content</b>',
        },
      });

      expect(findToggleButton().attributes('title')).toBe('Show details');
      expect(findToggleButton().attributes('aria-label')).toBe('Show details');
    });

    it('does not display the content slot until toggle is clicked', async () => {
      createComponent({
        propsData: {
          isCollapsible: true,
        },
        slots: {
          content: '<b>More complex content</b>',
        },
      });

      expect(findExpandedSection().exists()).toBe(false);
      findToggleButton().vm.$emit('click');
      await nextTick();
      expect(findExpandedSection().text()).toBe('More complex content');
    });

    it('emits a toggle even when button is toggled', () => {
      createComponent({
        propsData: {
          isCollapsible: true,
        },
        slots: {
          content: '<b>More complex content</b>',
        },
      });

      expect(findExpandedSection().exists()).toBe(false);
      findToggleButton().vm.$emit('click');
      expect(wrapper.emitted('toggle')).toEqual([[{ expanded: true }]]);
    });

    it('does not display the toggle button if isCollapsible is false', () => {
      createComponent({
        propsData: {
          isCollapsible: false,
        },
      });

      expect(findToggleButton().exists()).toBe(false);
    });

    it('fetches expanded data when clicked for the first time', async () => {
      const mockDataCollapsed = {
        headers: {},
        status: HTTP_STATUS_OK,
        data: { vulnerabilities: [{ vuln: 1 }] },
      };

      const mockDataExpanded = {
        headers: {},
        status: HTTP_STATUS_OK,
        data: { vulnerabilities: [{ vuln: 2 }] },
      };

      const fetchExpandedData = jest.fn().mockResolvedValue(mockDataExpanded);

      createComponent({
        propsData: {
          isCollapsible: true,
          fetchCollapsedData: () => Promise.resolve(mockDataCollapsed),
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      // First fetches the collapsed data
      expect(wrapper.emitted('input')[0][0]).toEqual({
        collapsed: mockDataCollapsed.data,
        expanded: null,
      });

      // Then fetches the expanded data
      expect(wrapper.emitted('input')[1][0]).toEqual({
        collapsed: null,
        expanded: mockDataExpanded.data,
      });

      // Triggering a click does not call the expanded data again
      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(fetchExpandedData).toHaveBeenCalledTimes(1);
    });

    it('allows refetching when fetch expanded data returns an error', async () => {
      const fetchExpandedData = jest.fn().mockRejectedValue({ error: true });

      createComponent({
        propsData: {
          isCollapsible: true,
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      // First fetches the collapsed data
      expect(wrapper.emitted('input')[0][0]).toEqual({
        collapsed: undefined,
        expanded: null,
      });

      expect(fetchExpandedData).toHaveBeenCalledTimes(1);
      expect(wrapper.emitted('input')).toHaveLength(1); // Should not an emit an input call because request failed

      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(fetchExpandedData).toHaveBeenCalledTimes(2);
    });

    it('resets the error message when another request is fetched', async () => {
      const fetchExpandedData = jest.fn().mockRejectedValue({ error: true });

      createComponent({
        propsData: {
          isCollapsible: true,
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.findByText('Failed to load').exists()).toBe(true);
      fetchExpandedData.mockImplementation(() => new Promise(() => {}));

      findToggleButton().vm.$emit('click');
      await nextTick();

      expect(wrapper.findByText('Failed to load').exists()).toBe(false);
    });
  });

  describe('telemetry - enabled', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isCollapsible: true,
          actionButtons: [
            {
              trackFullReportClicked: true,
              href: '#',
              target: '_blank',
              id: 'full-report-button',
              text: 'Full report',
            },
          ],
        },
      });
    });

    it('should call create a telemetry hub', () => {
      expect(wrapper.vm.telemetryHub).not.toBe(null);
    });

    it('should call the viewed state', async () => {
      await nextTick();
      expect(wrapper.vm.telemetryHub.viewed).toHaveBeenCalledTimes(1);
    });

    it('when full report is clicked it should call the respective telemetry event', async () => {
      expect(wrapper.vm.telemetryHub.fullReportClicked).not.toHaveBeenCalled();
      wrapper.findByText('Full report').vm.$emit('click');
      await nextTick();
      expect(wrapper.vm.telemetryHub.fullReportClicked).toHaveBeenCalledTimes(1);
    });
  });

  describe('telemetry - disabled', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isCollapsible: true,
          telemetry: false,
        },
      });
    });

    it('should not call create a telemetry hub', () => {
      expect(wrapper.vm.telemetryHub).toBe(null);
    });
  });

  describe('dynamic content', () => {
    const content = [
      {
        id: 'row-id',
        header: ['This is a header', 'This is a subheader'],
        text: 'Main text for the row',
        subtext: 'Optional: Smaller sub-text to be displayed below the main text',
      },
    ];

    beforeEach(() => {
      createComponent({
        mountFn: mountExtended,
        propsData: {
          isCollapsible: true,
          content,
        },
      });
    });

    it('uses a dynamic scroller to show the items', async () => {
      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(findDynamicScroller().props('items')).toEqual(content);
    });

    it('renders the dynamic content inside the dynamic scroller', async () => {
      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(wrapper.findByText('Main text for the row').exists()).toBe(true);
    });
  });
});
