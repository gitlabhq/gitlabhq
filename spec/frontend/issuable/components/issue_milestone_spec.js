import { shallowMount } from '@vue/test-utils';
import { mockMilestone } from 'jest/boards/mock_data';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('IssueMilestone component', () => {
  let wrapper;

  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);

  const milestone = { ...mockMilestone, id: 'gid://gitlab/Milestone/1' };

  const createComponent = (props = milestone) =>
    shallowMount(IssueMilestone, { propsData: { milestone: props }, stubs: { WorkItemAttribute } });

  beforeEach(() => {
    wrapper = createComponent();
  });

  it.each`
    prop          | value
    ${'iconName'} | ${'milestone'}
    ${'title'}    | ${milestone.title}
  `('passes $prop to WorkItemAttribute', ({ prop, value }) => {
    expect(findWorkItemAttribute().props(prop)).toBe(value);
  });

  it('passes popover attributes to WorkItemAttribute', () => {
    expect(findWorkItemAttribute().props('popoverAttributes')).toEqual({
      'data-reference-type': 'milestone',
      'data-placement': 'top',
      'data-milestone': 1,
    });
  });
});
