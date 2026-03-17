import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('IssuableMilestone component', () => {
  let wrapper;

  const milestoneObject = () => ({
    id: 'gid://gitlab/Milestone/1',
    title: 'My milestone',
    webPath: '/milestone/webPath',
  });

  const findWorkItemAttribute = () => wrapper.findComponent(WorkItemAttribute);

  const mountComponent = ({ milestone = milestoneObject() } = {}) =>
    shallowMountExtended(IssuableMilestone, {
      propsData: { milestone },
      stubs: { WorkItemAttribute },
    });

  it('renders milestone link', () => {
    wrapper = mountComponent();
    const milestoneEl = wrapper.findByTestId('issuable-milestone');

    expect(findWorkItemAttribute().props('title')).toBe('My milestone');
    expect(milestoneEl.findComponent(GlIcon).props('name')).toBe('milestone');
    expect(findWorkItemAttribute().props('href')).toBe('/milestone/webPath');
    expect(findWorkItemAttribute().props('isLink')).toBe(true);
  });

  it('navigates to milestone link when clicked', () => {
    wrapper = mountComponent();
    const milestoneLink = findWorkItemAttribute().props('href');

    expect(milestoneLink).toBe('/milestone/webPath');
    expect(findWorkItemAttribute().props('isLink')).toBe(true);
  });

  it('passes popover attributes to WorkItemAttribute', () => {
    wrapper = mountComponent();

    expect(findWorkItemAttribute().props('popoverAttributes')).toEqual({
      'data-reference-type': 'milestone',
      'data-placement': 'top',
      'data-milestone': 1,
    });
  });
});
