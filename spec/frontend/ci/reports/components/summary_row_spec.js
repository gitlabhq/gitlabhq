import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import SummaryRow from '~/ci/reports/components/summary_row.vue';

describe('Summary row', () => {
  let wrapper;

  const summary = 'SAST detected 1 new vulnerability and 1 fixed vulnerability';
  const popoverOptions = {
    title: 'Static Application Security Testing (SAST)',
    content: '<a>Learn more about SAST</a>',
  };
  const statusIcon = 'warning';

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = extendedWrapper(
      mount(SummaryRow, {
        propsData: {
          summary,
          popoverOptions,
          statusIcon,
          ...props,
        },
        slots,
      }),
    );
  };

  const findSummary = () => wrapper.findByTestId('summary-row-description');
  const findStatusIcon = () => wrapper.findByTestId('summary-row-icon');
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);

  it('renders provided summary', () => {
    createComponent();
    expect(findSummary().text()).toContain(summary);
  });

  it('renders provided icon', () => {
    createComponent();
    expect(findStatusIcon().classes()).toContain('js-ci-status-icon-warning');
  });

  it('renders help popover if popoverOptions are provided', () => {
    createComponent();
    expect(findHelpPopover().props('options')).toEqual(popoverOptions);
  });

  it('does not render help popover if popoverOptions are not provided', () => {
    createComponent({ props: { popoverOptions: null } });
    expect(findHelpPopover().exists()).toBe(false);
  });

  describe('summary slot', () => {
    it('replaces the summary prop', () => {
      const summarySlotContent = 'Summary slot content';
      createComponent({ slots: { summary: summarySlotContent } });

      expect(wrapper.text()).not.toContain(summary);
      expect(findSummary().text()).toContain(summarySlotContent);
    });
  });
});
