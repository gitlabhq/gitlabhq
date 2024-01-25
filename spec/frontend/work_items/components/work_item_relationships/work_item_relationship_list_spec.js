import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemRelationshipList from '~/work_items/components/work_item_relationships/work_item_relationship_list.vue';
import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';

import { mockBlockingLinkedItem } from '../../mock_data';

describe('WorkItemRelationshipList', () => {
  let wrapper;
  const mockLinkedItems = mockBlockingLinkedItem.linkedItems.nodes;
  const workItemFullPath = 'test-project-path';

  const createComponent = ({ linkedItems = [], heading = 'Blocking', canUpdate = true } = {}) => {
    wrapper = shallowMountExtended(WorkItemRelationshipList, {
      propsData: {
        linkedItems,
        heading,
        canUpdate,
        workItemFullPath,
      },
    });
  };

  const findHeading = () => wrapper.findByTestId('work-items-list-heading');
  const findWorkItemLinkChildContents = () => wrapper.findComponent(WorkItemLinkChildContents);

  beforeEach(() => {
    createComponent({ linkedItems: mockLinkedItems });
  });

  it('renders linked item list', () => {
    expect(findHeading().text()).toBe('Blocking');
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders work item link child contents with correct props', () => {
    expect(findWorkItemLinkChildContents().props()).toMatchObject({
      childItem: mockLinkedItems[0].workItem,
      canUpdate: true,
      workItemFullPath,
    });
  });
});
