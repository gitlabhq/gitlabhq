import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemRelationshipIcons from '~/work_items/components/shared/work_item_relationship_icons.vue';
import { LINKED_CATEGORIES_MAP } from '~/work_items/constants';

import { mockLinkedItems } from '../../mock_data';

describe('WorkItemRelationshipIcons', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemRelationshipIcons, {
      propsData: {
        linkedWorkItems: mockLinkedItems.linkedItems.nodes,
        workItemType: 'Task',
      },
    });
  };

  const findBlockedIcon = () => wrapper.findByTestId('relationship-blocked-by-icon');
  const findBlockingIcon = () => wrapper.findByTestId('relationship-blocks-icon');

  const blockedItems = mockLinkedItems.linkedItems.nodes.filter(
    (item) => item.linkType === LINKED_CATEGORIES_MAP.IS_BLOCKED_BY,
  );
  const blockingItems = mockLinkedItems.linkedItems.nodes.filter(
    (item) => item.linkType === LINKED_CATEGORIES_MAP.BLOCKS,
  );

  it('renders the correct number of blocked and blocking items', () => {
    createComponent();

    expect(findBlockedIcon().exists()).toBe(true);
    expect(findBlockedIcon().text()).toContain(blockedItems.length.toString());

    expect(findBlockingIcon().exists()).toBe(true);
    expect(findBlockingIcon().text()).toContain(blockingItems.length.toString());
  });

  it('renders the correct aria labels for icons', () => {
    createComponent();

    expect(findBlockedIcon().attributes('aria-label')).toBe('Task is blocked by 1 item');
    expect(findBlockingIcon().attributes('aria-label')).toBe('Task blocks 1 item');
  });

  it('renders only blocked icon if no blocking relationship exists', () => {
    createComponent({ linkedWorkItems: blockedItems });

    expect(findBlockedIcon().exists()).toBe(true);
    expect(findBlockingIcon().exists()).toBe(true);
    expect(findBlockedIcon().text()).toContain(blockedItems.length.toString());
  });

  it('renders only blocking icon if no blocked relationship exists', () => {
    createComponent({ linkedWorkItems: blockingItems });

    expect(findBlockingIcon().exists()).toBe(true);
    expect(findBlockedIcon().exists()).toBe(true);
    expect(findBlockingIcon().text()).toContain(blockedItems.length.toString());
  });
});
