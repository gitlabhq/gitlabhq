import DraggableList from 'vuedraggable';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import WorkItemRelationshipList from '~/work_items/components/work_item_relationships/work_item_relationship_list.vue';
import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';

import removeLinkedItemsMutation from '~/work_items/graphql/remove_linked_items.mutation.graphql';
import addLinkedItemsMutation from '~/work_items/graphql/add_linked_items.mutation.graphql';

import { mockBlockingLinkedItem } from '../../mock_data';

jest.mock('~/lib/utils/url_utility');

describe('WorkItemRelationshipList', () => {
  let wrapper;
  let mutationSpy = jest.fn();
  const mockLinkedItems = mockBlockingLinkedItem.linkedItems.nodes;
  const workItemFullPath = 'test-project-path';

  const createComponent = ({
    parentWorkItemId = 'gid://gitlab/WorkItem/1',
    parentWorkItemIid = '2',
    linkedItems = [],
    relationshipType = 'blocks',
    heading = 'Blocking',
    canUpdate = true,
    isLoggedIn = true,
    activeChildItemId = null,
  } = {}) => {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    wrapper = shallowMountExtended(WorkItemRelationshipList, {
      propsData: {
        parentWorkItemId,
        parentWorkItemIid,
        linkedItems,
        relationshipType,
        heading,
        canUpdate,
        workItemFullPath,
        activeChildItemId,
      },
      mocks: {
        $apollo: {
          mutate: mutationSpy,
        },
      },
    });
  };

  const findHeading = () => wrapper.findByTestId('work-items-list-heading');
  const findDraggableWorkItemsList = () => wrapper.findComponent(DraggableList);
  const findWorkItemLinkChildContents = () => wrapper.findComponent(WorkItemLinkChildContents);

  const mockFrom = {
    dataset: {
      relationshipType: 'blocks',
    },
  };
  const mockTo = {
    dataset: {
      relationshipType: 'is_blocked_by',
    },
    prepend: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
  };

  it('renders linked item list', () => {
    createComponent({ linkedItems: mockLinkedItems });
    expect(findHeading().text()).toBe('Blocking');
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders work item list with drag and drop ability when canUpdate is true', () => {
    createComponent({ linkedItems: mockLinkedItems });
    expect(findDraggableWorkItemsList().exists()).toBe(true);
  });

  it('renders work item link child contents with correct props', () => {
    createComponent({ linkedItems: mockLinkedItems });
    expect(findWorkItemLinkChildContents().props()).toMatchObject({
      childItem: mockLinkedItems[0].workItem,
      canUpdate: true,
      workItemFullPath,
      showWeight: true,
    });
  });

  it('highlights the item when the drawer is opened', () => {
    const ACTIVE_DRAWER_CLASS = 'gl-border-default gl-bg-blue-50 hover:gl-bg-blue-50';
    createComponent({
      linkedItems: mockLinkedItems,
      activeChildItemId: mockLinkedItems[0].workItem.id,
    });
    expect(findWorkItemLinkChildContents().attributes('class')).toContain(ACTIVE_DRAWER_CLASS);
  });

  it('opens the drawer on click when the item is not an incident', () => {
    createComponent({ linkedItems: mockLinkedItems });
    findWorkItemLinkChildContents().vm.$emit('click');

    expect(wrapper.emitted('showModal')).toEqual([
      [expect.objectContaining({ child: mockLinkedItems[0].workItem })],
    ]);
  });

  it('redirects to the url of the linked item on click when the item is an incident', () => {
    const mockLinkedItemsWithIncident = [
      {
        ...mockLinkedItems[0],
        workItem: {
          ...mockLinkedItems[0].workItem,
          workItemType: {
            id: 'gid://gitlab/WorkItems::Type/5',
            name: 'Incident',
            iconName: 'issue-type-incident',
            __typename: 'WorkItemType',
          },
        },
      },
    ];

    createComponent({ linkedItems: mockLinkedItemsWithIncident });
    findWorkItemLinkChildContents().vm.$emit('click');

    expect(visitUrl).toHaveBeenCalledWith(mockLinkedItemsWithIncident[0].workItem.webUrl);
  });

  describe('drag start', () => {
    beforeEach(() => {
      createComponent({ linkedItems: mockLinkedItems });
      jest.spyOn(document, 'addEventListener');
      findDraggableWorkItemsList().vm.$emit('start', {
        to: mockTo,
      });
    });

    it('adds a class `is-dragging` to document body', () => {
      expect(document.body.classList.contains('is-dragging')).toBe(true);
    });

    it('attaches `keyup` event listener on document to support cancel on Esc key press', () => {
      expect(document.addEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
    });

    it('ignores click events originating from anchor elements on the next event loop for Firefox', () => {
      expect(mockTo.addEventListener).toHaveBeenCalledWith('click', expect.any(Function), {
        capture: true,
        once: true,
      });
    });

    it('detaches click listener attached previously for Firefox', () => {
      jest.runAllTimers();

      expect(mockTo.removeEventListener).toHaveBeenCalled();
    });
  });

  describe('drag move', () => {
    beforeEach(() => {
      createComponent({ linkedItems: mockLinkedItems });
      // We're manually calling `move` function here as VueDraggable doesn't expose it as an event
      // even when Sortable.js has already defined it https://github.com/SortableJS/Sortable?tab=readme-ov-file#options
      findDraggableWorkItemsList().vm.move({
        from: mockFrom,
        to: mockTo,
        dragged: document.createElement('ul'),
      });
    });

    it('always inserts to the top of the target list', () => {
      expect(mockTo.prepend).toHaveBeenCalledWith(expect.any(HTMLElement));
    });

    it('prevents insertion if relationship type did not change', () => {
      expect(
        findDraggableWorkItemsList().vm.move({
          from: mockFrom,
          to: mockFrom,
          dragged: findDraggableWorkItemsList().vm.element,
        }),
      ).toBe(true);
    });
  });

  describe('drag end', () => {
    const mockItem = {
      dataset: {
        workItemId: mockLinkedItems[0].workItem.id,
      },
    };

    const emitDragEnd = async (from, to) => {
      await findDraggableWorkItemsList().vm.$emit('end', {
        from,
        to,
        item: mockItem,
      });
    };

    beforeEach(() => {
      mutationSpy = jest
        .fn()
        .mockResolvedValueOnce({
          data: {
            workItemRemoveLinkedItems: {
              errors: [],
            },
          },
        })
        .mockResolvedValueOnce({
          data: {
            workItemAddLinkedItems: {
              errors: [],
            },
          },
        });

      createComponent({ linkedItems: mockLinkedItems });
    });

    it('removes class `is-dragging` from document body', async () => {
      document.body.classList.add('is-dragging');

      await emitDragEnd(mockFrom, mockTo);

      expect(document.body.classList.contains('is-dragging')).toBe(false);
    });

    it('detaches keyup listener on document which was added for Esc key support', async () => {
      jest.spyOn(document, 'removeEventListener');
      await emitDragEnd(mockFrom, mockTo);

      expect(document.removeEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
    });

    it('does not emit updateLinkedItem event when relationship type did not change', async () => {
      await emitDragEnd(mockFrom, mockFrom);

      expect(wrapper.emitted('updateLinkedItem')).toBeUndefined();
    });

    it('emits updateLinkedItem event when relationship type did change', async () => {
      await emitDragEnd(mockFrom, mockTo);

      expect(wrapper.emitted('updateLinkedItem')).toEqual([
        [
          {
            linkedItem: mockLinkedItems[0],
            fromRelationshipType: mockFrom.dataset.relationshipType,
            toRelationshipType: mockTo.dataset.relationshipType,
          },
        ],
      ]);
    });

    it('triggers mutation to remove item from source list', async () => {
      await emitDragEnd(mockFrom, mockTo);

      expect(mutationSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: removeLinkedItemsMutation,
          variables: {
            input: {
              id: 'gid://gitlab/WorkItem/1',
              workItemsIds: [mockItem.dataset.workItemId],
            },
          },
        }),
      );
    });

    it('triggers mutation to add item to target list', async () => {
      await emitDragEnd(mockFrom, mockTo);

      await waitForPromises();

      expect(mutationSpy).toHaveBeenCalledTimes(2);

      expect(mutationSpy).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({
          mutation: addLinkedItemsMutation,
          variables: {
            input: {
              id: 'gid://gitlab/WorkItem/1',
              linkType: 'BLOCKED_BY',
              workItemsIds: [mockItem.dataset.workItemId],
            },
          },
        }),
      );
    });
  });
});
