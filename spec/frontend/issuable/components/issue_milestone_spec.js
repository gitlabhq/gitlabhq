import { GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockMilestone } from 'jest/boards/mock_data';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';

describe('IssueMilestone component', () => {
  let wrapper;

  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const createComponent = (milestone = mockMilestone) =>
    shallowMount(IssueMilestone, { propsData: { milestone } });

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders milestone icon', () => {
    expect(wrapper.findComponent(GlIcon).props('name')).toBe('milestone');
  });

  it('renders milestone title', () => {
    expect(wrapper.find('.milestone-title').text()).toBe(mockMilestone.title);
  });

  describe('tooltip', () => {
    it('renders `Milestone`', () => {
      expect(findTooltip().text()).toContain('Milestone');
    });

    it('renders milestone title', () => {
      expect(findTooltip().text()).toContain(mockMilestone.title);
    });

    describe('humanized dates', () => {
      it('renders `Expired` when there is a due date in the past', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '2019-12-31', start_date: '' });

        expect(findTooltip().text()).toContain('Expired 6 months ago(December 31, 2019)');
      });

      it('renders `remaining` when there is a due date in the future', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '2020-12-31', start_date: '' });

        expect(findTooltip().text()).toContain('5 months remaining(December 31, 2020)');
      });

      it('renders `Started` when there is a start date in the past', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '', start_date: '2019-12-31' });

        expect(findTooltip().text()).toContain('Started 6 months ago(December 31, 2019)');
      });

      it('renders `Starts` when there is a start date in the future', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '', start_date: '2020-12-31' });

        expect(findTooltip().text()).toContain('Starts in 5 months(December 31, 2020)');
      });
    });
  });
});
