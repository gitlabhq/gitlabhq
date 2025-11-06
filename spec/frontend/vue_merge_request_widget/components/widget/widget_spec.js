import { GlAnimatedChevronLgDownUpIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { assertProps } from 'helpers/assert_props';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import WidgetContentRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';
import * as logger from '~/lib/logger';
import axios from '~/lib/utils/axios_utils';
import { parseBoolean } from '~/lib/utils/common_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/vue_merge_request_widget/components/widget/telemetry', () => ({
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
  const findToggleChevron = () => findToggleButton().findComponent(GlAnimatedChevronLgDownUpIcon);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findDynamicScroller = () => wrapper.findByTestId('dynamic-content-scroller');

  const createComponent = async ({
    propsData,
    slots,
    mountFn = shallowMountExtended,
    provide = {},
  } = {}) => {
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
      provide,
      stubs: {
        StatusIcon,
        ActionButtons,
        ContentRow: WidgetContentRow,
        RouterLink: true,
      },
    });

    await axios.waitForAll();
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
          fetchCollapsedData: jest.fn().mockResolvedValue({}),
        },
      });

      await nextTick();
      expect(wrapper.text()).toContain('Loading');
      await axios.waitForAll();
      expect(wrapper.text()).not.toContain('Loading');
    });
  });

  describe('fetch', () => {
    it('calls fetchCollapsedData properly when multiPolling is false', async () => {
      const mockData = { headers: {}, status: HTTP_STATUS_OK, data: { vulnerabilities: [] } };
      const fetchCollapsedData = jest.fn().mockResolvedValue(mockData);
      createComponent({ propsData: { fetchCollapsedData } });
      await waitForPromises();
      expect(fetchCollapsedData).toHaveBeenCalledTimes(1);
    });

    it('calls fetchCollapsedData properly when multiPolling is true', async () => {
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

      const fetchCollapsedData = [
        jest.fn().mockResolvedValue(mockData1),
        jest.fn().mockResolvedValue(mockData2),
      ];

      createComponent({
        propsData: {
          multiPolling: true,
          fetchCollapsedData: () => fetchCollapsedData,
        },
      });

      await waitForPromises();

      expect(fetchCollapsedData[0]).toHaveBeenCalledTimes(1);
      expect(fetchCollapsedData[1]).toHaveBeenCalledTimes(1);
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
    it('displays summary property when summary slot is not provided', async () => {
      await createComponent({
        propsData: {
          summary: { title: 'Hello world' },
        },
      });

      expect(wrapper.findByTestId('widget-extension-top-level-summary').text()).toBe('Hello world');
    });

    it('displays content property when content slot is not provided', async () => {
      const content = [
        {
          id: 'row-1',
          header: ['Header 1', 'Subheader 1'],
          text: 'Content text 1',
        },
        {
          id: 'row-2',
          header: ['Header 2'],
          text: 'Content text 2',
        },
      ];

      await createComponent({
        mountFn: mountExtended,
        propsData: {
          isCollapsible: true,
          content,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.findByText('Content text 1').exists()).toBe(true);
      expect(wrapper.findByText('Content text 2').exists()).toBe(true);
    });

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
    it('displays the toggle button correctly', async () => {
      await createComponent({
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

    it('displays the chevron correctly when toggle is clicked', async () => {
      await createComponent({
        propsData: {
          isCollapsible: true,
        },
        slots: {
          content: '<b>More complex content</b>',
        },
      });

      // Vue compat doesn't know about component props if it extends other component
      expect(
        findToggleChevron().props('isOn') ?? parseBoolean(findToggleChevron().attributes('is-on')),
      ).toBe(false);

      findToggleButton().vm.$emit('click');
      await nextTick();
      expect(
        findToggleChevron().props('isOn') ?? parseBoolean(findToggleChevron().attributes('is-on')),
      ).toBe(true);
    });
    it('does not display the content slot until toggle is clicked', async () => {
      await createComponent({
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

    it('emits a toggle even when button is toggled', async () => {
      await createComponent({
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

    it('does not display the toggle button if isCollapsible is false', async () => {
      await createComponent({
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
      const fetchCollapsedData = jest.fn().mockResolvedValue(mockDataCollapsed);

      await createComponent({
        propsData: {
          isCollapsible: true,
          fetchCollapsedData,
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(fetchCollapsedData).toHaveBeenCalledTimes(1);
      expect(fetchExpandedData).toHaveBeenCalledTimes(1);

      // Triggering a click does not call the expanded data again
      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(fetchExpandedData).toHaveBeenCalledTimes(1);
    });

    it('allows refetching when fetch expanded data returns an error', async () => {
      const fetchExpandedData = jest.fn().mockRejectedValue({ error: true });

      await createComponent({
        propsData: {
          isCollapsible: true,
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(fetchExpandedData).toHaveBeenCalledTimes(1);

      findToggleButton().vm.$emit('click');
      await waitForPromises();
      expect(fetchExpandedData).toHaveBeenCalledTimes(2);
    });

    it('resets the error message when another request is fetched', async () => {
      const fetchExpandedData = jest.fn().mockRejectedValue({ error: true });

      await createComponent({
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

      wrapper.findByTestId('extension-actions-button').vm.$emit('click');
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

    beforeEach(async () => {
      await createComponent({
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

  describe('when mrReportsTab is enabled', () => {
    beforeEach(() => {
      window.gl = { mrWidgetData: { reportsTabPath: 'reportsTabPath' } };
      window.mrTabs = { tabShown: jest.fn() };
      jest.spyOn(window.history, 'replaceState');
    });

    it('does not render toggle button', async () => {
      await createComponent({
        propsData: {
          isCollapsible: true,
          summary: { title: 'Hello world' },
        },
        provide: { glFeatures: { mrReportsTab: true } },
      });

      expect(findToggleButton().exists()).toBe(false);
    });

    it('renders view reports action button', async () => {
      await createComponent({
        propsData: {
          isCollapsible: true,
          summary: { title: 'Hello world' },
        },
        provide: { glFeatures: { mrReportsTab: true } },
      });

      expect(findActionButtons().props('tertiaryButtons')).toEqual([
        expect.objectContaining({ href: 'reportsTabPath/test', text: 'View report' }),
      ]);
    });

    it('calls mrTabs.tabShown when clicking action button', async () => {
      await createComponent({
        propsData: {
          isCollapsible: true,
          summary: { title: 'Hello world' },
        },
        provide: { glFeatures: { mrReportsTab: true } },
      });

      wrapper.findByTestId('extension-actions-button').vm.$emit('click', { preventDefault() {} });

      await nextTick();

      expect(window.mrTabs.tabShown).toHaveBeenCalledWith('reports');
      expect(window.history.replaceState).toHaveBeenCalledWith(null, null, 'reportsTabPath/test');
    });
  });

  describe('when reportsTabSidebar is true', () => {
    it('renders ReportListItem', async () => {
      await createComponent({
        propsData: {
          isCollapsible: true,
          summary: { title: 'Hello world' },
        },
        provide: { reportsTabSidebar: true },
      });

      expect(wrapper.findComponent(ReportListItem).exists()).toBe(true);
    });
  });

  describe('loading states', () => {
    it('shows loading icon when loadingState is status_icon', async () => {
      await createComponent({
        propsData: {
          loadingState: 'status_icon',
        },
      });

      expect(findStatusIcon().props('isLoading')).toBe(true);
    });

    it('shows loading text when loadingState is collapsed', async () => {
      await createComponent({
        propsData: {
          loadingState: 'collapsed',
          loadingText: 'Custom loading text',
        },
      });

      expect(wrapper.text()).toContain('Custom loading text');
    });

    it('emits is-loading event when loading state changes', async () => {
      const fetchCollapsedData = jest
        .fn()
        .mockReturnValue(Promise.resolve({ headers: {}, status: HTTP_STATUS_OK, data: {} }));

      createComponent({ propsData: { fetchCollapsedData } });

      expect(wrapper.emitted('is-loading')).toBeUndefined();

      await waitForPromises();
      expect(wrapper.emitted('is-loading')).toEqual([[false]]);
    });
  });

  describe('error handling', () => {
    it('displays custom error text when provided', () => {
      createComponent({
        propsData: {
          hasError: true,
          errorText: 'Custom error message',
        },
      });

      expect(wrapper.findByText('Custom error message').exists()).toBe(true);
    });

    it('shows failed status icon when there is a summary error', async () => {
      createComponent({
        propsData: {
          fetchCollapsedData: jest.fn().mockRejectedValue('Error'),
        },
      });

      await waitForPromises();
      expect(findStatusIcon().props('iconName')).toBe('failed');
    });

    it('displays content error when expanded data fetch fails', async () => {
      const fetchExpandedData = jest.fn().mockRejectedValue('Expanded error');

      await createComponent({
        propsData: {
          isCollapsible: true,
          fetchExpandedData,
        },
      });

      findToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.findByText('Failed to load').exists()).toBe(true);
    });
  });

  describe('widget name validation', () => {
    it('accepts valid widget names starting with Widget', () => {
      expect(() => {
        assertProps(Widget, { widgetName: 'WidgetSecurity', isCollapsible: false });
      }).not.toThrow();
    });

    it('rejects widget names not starting with Widget', () => {
      expect(() => {
        assertProps(Widget, { widgetName: 'SecurityWidget' });
      }).toThrow();
    });
  });

  describe('poll management', () => {
    it('stops polling when component is unmounted', async () => {
      const fetchCollapsedData = jest
        .fn()
        .mockReturnValue(
          Promise.resolve({ headers: { 'POLL-INTERVAL': 3000 }, status: HTTP_STATUS_OK, data: {} }),
        );

      createComponent({ propsData: { fetchCollapsedData } });

      // Poll 10 times
      for (let i = 0; i < 10; i += 1) {
        expect(fetchCollapsedData).toHaveBeenCalledTimes(i + 1);
        // eslint-disable-next-line no-await-in-loop
        await waitForPromises();
        jest.advanceTimersByTime(3000);
      }

      fetchCollapsedData.mockClear();

      wrapper.destroy();

      // Wait another round
      await waitForPromises();
      jest.advanceTimersByTime(3000);

      expect(fetchCollapsedData).not.toHaveBeenCalled();
    });
  });
});
