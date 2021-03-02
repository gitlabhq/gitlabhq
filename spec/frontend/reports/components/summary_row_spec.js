import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SummaryRow from '~/reports/components/summary_row.vue';

describe('Summary row', () => {
  let wrapper;

  const props = {
    summary: 'SAST detected 1 new vulnerability and 1 fixed vulnerability',
    popoverOptions: {
      title: 'Static Application Security Testing (SAST)',
      content: '<a>Learn more about SAST</a>',
    },
    statusIcon: 'warning',
  };

  const createComponent = ({ propsData = {}, slots = {} } = {}) => {
    wrapper = extendedWrapper(
      mount(SummaryRow, {
        propsData: {
          ...props,
          ...propsData,
        },
        slots,
      }),
    );
  };

  const findSummary = () => wrapper.findByTestId('summary-row-description');
  const findStatusIcon = () => wrapper.findByTestId('summary-row-icon');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders provided summary', () => {
    createComponent();
    expect(findSummary().text()).toContain(props.summary);
  });

  it('renders provided icon', () => {
    createComponent();
    expect(findStatusIcon().classes()).toContain('js-ci-status-icon-warning');
  });

  describe('summary slot', () => {
    it('replaces the summary prop', () => {
      const summarySlotContent = 'Summary slot content';
      createComponent({ slots: { summary: summarySlotContent } });

      expect(wrapper.text()).not.toContain(props.summary);
      expect(findSummary().text()).toContain(summarySlotContent);
    });
  });
});
