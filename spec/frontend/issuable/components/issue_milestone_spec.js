import { GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockMilestone } from 'jest/boards/mock_data';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('IssueMilestone component', () => {
  let wrapper;

  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);

  const createComponent = (milestone = mockMilestone) =>
    shallowMount(IssueMilestone, { propsData: { milestone }, stubs: { WorkItemAttribute } });

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders milestone icon', () => {
    expect(findWorkItemAttribute().props('iconName')).toBe('milestone');
  });

  it('renders milestone title', () => {
    expect(findWorkItemAttribute().props('title')).toBe(mockMilestone.title);
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

        expect(findTooltip().text()).toContain('Expired 6 months ago(Dec 31, 2019)');
      });

      it('renders `remaining` when there is a due date in the future', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '2020-12-31', start_date: '' });

        expect(findTooltip().text()).toContain('5 months remaining(Dec 31, 2020)');
      });

      it('renders `Started` when there is a start date in the past', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '', start_date: '2019-12-31' });

        expect(findTooltip().text()).toContain('Started 6 months ago(Dec 31, 2019)');
      });

      it('renders `Starts` when there is a start date in the future', () => {
        wrapper = createComponent({ ...mockMilestone, due_date: '', start_date: '2020-12-31' });

        expect(findTooltip().text()).toContain('Starts in 5 months(Dec 31, 2020)');
      });
    });
  });
});
