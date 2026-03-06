import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';
import ActionButtons from '~/vue_merge_request_widget/components/widget/action_buttons.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('ReportSection', () => {
  let wrapper;

  const findHeaderStatusIcon = () => wrapper.findComponent(StatusIcon);
  const findActionButtons = () => wrapper.findComponent(ActionButtons);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findSummary = () => wrapper.findByTestId('summary');
  const findLoadingText = () => wrapper.findByTestId('loading-text');

  const DEFAULT_PROPS = {
    summary: { title: 'Detected 3 new licenses' },
    actionButtons: [{ text: 'Full report', href: '/report' }],
    helpPopover: {
      options: { title: 'Help title' },
      content: {
        text: 'Help text',
        learnMorePath: '/learn-more',
      },
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ReportSection, {
      propsData: { ...DEFAULT_PROPS, ...props },
    });
  };

  describe('loading', () => {
    it('passes isLoading to status icon', () => {
      createComponent({ isLoading: true });

      expect(findHeaderStatusIcon().props('isLoading')).toBe(true);
    });

    it('shows loading text when loading', () => {
      createComponent({ isLoading: true, loadingText: 'Loading message' });

      expect(findLoadingText().text()).toBe('Loading message');
    });

    it('hides summary, help popover, and action buttons when loading', () => {
      createComponent({ isLoading: true });

      expect(findSummary().exists()).toBe(false);
      expect(findHelpPopover().exists()).toBe(false);
      expect(findActionButtons().exists()).toBe(false);
    });

    it('shows content when not loading', () => {
      createComponent();

      expect(findSummary().exists()).toBe(true);
      expect(findHelpPopover().exists()).toBe(true);
      expect(findActionButtons().exists()).toBe(true);
    });
  });

  describe('summary', () => {
    it('renders summary title', () => {
      createComponent();

      expect(findSummary().text()).toBe(DEFAULT_PROPS.summary.title);
    });

    it('does not render summary when no title provided', () => {
      createComponent({ summary: {} });

      expect(findSummary().exists()).toBe(false);
    });
  });

  describe('status icon', () => {
    it('uses provided statusIconName', () => {
      createComponent({ statusIconName: 'warning' });

      expect(findHeaderStatusIcon().props('iconName')).toBe('warning');
    });

    it('defaults to neutral', () => {
      createComponent();

      expect(findHeaderStatusIcon().props('iconName')).toBe('neutral');
    });
  });

  describe('help popover', () => {
    it('renders help popover with content', () => {
      createComponent();

      expect(findHelpPopover().exists()).toBe(true);
      expect(findHelpPopover().props('options')).toEqual(DEFAULT_PROPS.helpPopover.options);
    });

    it('does not render help popover when not provided', () => {
      createComponent({ helpPopover: null });

      expect(findHelpPopover().exists()).toBe(false);
    });

    it('adds margin when action buttons are present', () => {
      createComponent();

      expect(findHelpPopover().classes()).toContain('gl-mr-3');
    });

    it('does not add margin when no action buttons', () => {
      createComponent({ actionButtons: [] });

      expect(findHelpPopover().classes()).not.toContain('gl-mr-3');
    });
  });

  describe('action buttons', () => {
    it('renders action buttons', () => {
      createComponent();

      expect(findActionButtons().exists()).toBe(true);
      expect(findActionButtons().props('tertiaryButtons')).toEqual(DEFAULT_PROPS.actionButtons);
    });

    it('does not render action buttons when empty', () => {
      createComponent({ actionButtons: [] });

      expect(findActionButtons().exists()).toBe(false);
    });
  });
});
