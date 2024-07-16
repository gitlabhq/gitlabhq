import { shallowMount } from '@vue/test-utils';
import WorkItemTreeChildren from '~/work_items/components/work_item_links/work_item_tree_children.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import { childrenWorkItems } from '../../mock_data';

describe('WorkItemTreeChildren', () => {
  let wrapper;

  const createComponent = ({ children = childrenWorkItems } = {}) => {
    wrapper = shallowMount(WorkItemTreeChildren, {
      propsData: {
        workItemType: 'Objective',
        workItemId: 'gid:://gitlab/WorkItem/1',
        children,
        canUpdate: true,
        showLabels: true,
      },
    });
  };

  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);
  const findWorkItemLinkChildItem = () => findWorkItemLinkChildItems().at(0);

  beforeEach(() => {
    createComponent();
  });

  it('renders all WorkItemLinkChildItems', () => {
    expect(findWorkItemLinkChildItems().length).toBe(4);
  });

  it('emits childItem from WorkItemLinkChildItems on `click` event', () => {
    const event = {
      childItem: 'gid://gitlab/WorkItem/2',
    };

    findWorkItemLinkChildItem().vm.$emit('click', event);

    expect(wrapper.emitted('click')).toEqual([[{ childItem: 'gid://gitlab/WorkItem/2' }]]);
  });

  it('emits immediate childItem on `click` event', () => {
    const event = expect.anything();

    findWorkItemLinkChildItem().vm.$emit('click', event);

    expect(wrapper.emitted('click')).toEqual([[{ childItem: 'gid://gitlab/WorkItem/2' }]]);
  });
});
