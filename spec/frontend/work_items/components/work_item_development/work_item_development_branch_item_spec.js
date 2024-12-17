import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { workItemRelatedBranchNodes } from 'jest/work_items/mock_data';
import WorkItemDevelopmentBranchItem from '~/work_items/components/work_item_development/work_item_development_branch_item.vue';

describe('WorkItemDevelopmentBranchItem', () => {
  let wrapper;

  const branchNode = workItemRelatedBranchNodes[0];

  const createComponent = ({ branch = branchNode } = {}) => {
    wrapper = shallowMount(WorkItemDevelopmentBranchItem, {
      propsData: {
        itemContent: branch,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);

  it('should render the comparePath and name with icon', () => {
    createComponent();
    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('branch');
    expect(findLink().attributes('href')).toBe(branchNode.comparePath);
    expect(findLink().text()).toBe(branchNode.name);
  });
});
