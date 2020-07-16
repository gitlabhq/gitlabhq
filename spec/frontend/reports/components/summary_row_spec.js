import { mount } from '@vue/test-utils';
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
    wrapper = mount(SummaryRow, {
      propsData: {
        ...props,
        ...propsData,
      },
      slots,
    });
  };

  const findSummary = () => wrapper.find('.report-block-list-issue-description-text');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders provided summary', () => {
    createComponent();
    expect(findSummary().text()).toEqual(props.summary);
  });

  it('renders provided icon', () => {
    createComponent();
    expect(wrapper.find('.report-block-list-icon span').classes()).toContain(
      'js-ci-status-icon-warning',
    );
  });

  describe('summary slot', () => {
    it('replaces the summary prop', () => {
      const summarySlotContent = 'Summary slot content';
      createComponent({ slots: { summary: summarySlotContent } });

      expect(wrapper.text()).not.toContain(props.summary);
      expect(findSummary().text()).toEqual(summarySlotContent);
    });
  });
});
