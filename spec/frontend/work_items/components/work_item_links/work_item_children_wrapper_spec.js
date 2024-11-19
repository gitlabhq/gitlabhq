import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Draggable from 'vuedraggable';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { ESC_KEY } from '~/lib/utils/keys';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import moveWorkItemMutation from '~/work_items/graphql/move_work_item.mutation.graphql';
import * as cacheUtils from '~/work_items/graphql/cache_utils';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import {
  changeWorkItemParentMutationResponse,
  childrenWorkItems,
  childrenWorkItemsObjectives,
  updateWorkItemMutationErrorResponse,
  workItemByIidResponseFactory,
  workItemHierarchyTreeResponse,
  mockMoveWorkItemMutationResponse,
} from '../../mock_data';

jest.mock('~/lib/utils/common_utils');

describe('WorkItemChildrenWrapper', () => {
  let wrapper;

  const $toast = {
    show: jest.fn(),
  };
  const getWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const updateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(changeWorkItemParentMutationResponse);
  const getWorkItemTreeQueryHandler = jest.fn().mockResolvedValue(workItemHierarchyTreeResponse);
  const moveWorkItemMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(mockMoveWorkItemMutationResponse);
  const moveWorkItemMutationFailureHandler = jest
    .fn()
    .mockResolvedValue(mockMoveWorkItemMutationResponse({ error: 'Error' }));
  const mockToggleHierarchyTreeChildResolver = jest.fn();

  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);
  const findFirstWorkItemLinkChildItem = () => findWorkItemLinkChildItems().at(0);
  const findDraggable = () => wrapper.findComponent(Draggable);
  const findChildItemsContainer = () => wrapper.findByTestId('child-items-container');

  Vue.use(VueApollo);

  const createComponent = ({
    workItemType = 'Objective',
    confidential = false,
    children = childrenWorkItems,
    isTopLevel = true,
    mutationHandler = updateWorkItemMutationHandler,
    disableContent = false,
    canUpdate = false,
    showClosed = true,
    moveWorkItemMutationHandler = moveWorkItemMutationSuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo(
      [
        [workItemByIidQuery, getWorkItemQueryHandler],
        [updateWorkItemMutation, mutationHandler],
        [getWorkItemTreeQuery, getWorkItemTreeQueryHandler],
        [moveWorkItemMutation, moveWorkItemMutationHandler],
      ],
      {
        Mutation: {
          toggleHierarchyTreeChild: mockToggleHierarchyTreeChildResolver,
        },
      },
    );

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: workItemByIidQuery,
      variables: { fullPath: 'test/project', iid: '1' },
      data: workItemByIidResponseFactory().data,
    });

    wrapper = shallowMountExtended(WorkItemChildrenWrapper, {
      apolloProvider: mockApollo,
      propsData: {
        fullPath: 'test/project',
        workItemType,
        workItemId: 'gid://gitlab/WorkItem/515',
        workItemIid: '1',
        confidential,
        children,
        isTopLevel,
        disableContent,
        canUpdate,
        showClosed,
        parent: workItemByIidResponseFactory().data.workspace.workItem,
      },
      mocks: {
        $toast,
      },
    });
  };

  it('renders all hierarchy widget children', () => {
    createComponent();

    const workItemLinkChildren = findWorkItemLinkChildItems();
    expect(workItemLinkChildren).toHaveLength(4);
    expect(workItemLinkChildren.at(0).props().childItem.confidential).toBe(
      childrenWorkItems[0].confidential,
    );
  });

  it('does not render children when show closed toggle is off', async () => {
    await createComponent({ showClosed: false });

    const workItemLinkChildren = findWorkItemLinkChildItems();
    expect(workItemLinkChildren).toHaveLength(3);
  });

  it('emits `show-modal` on `click` event', () => {
    createComponent();
    const event = {
      childItem: 'gid://gitlab/WorkItem/2',
    };

    findFirstWorkItemLinkChildItem().vm.$emit('click', event);

    expect(wrapper.emitted('show-modal')).toEqual([[{ event, child: event.childItem }]]);
  });

  it('emits `click` event when clicking on nested child', () => {
    createComponent({ isTopLevel: false });
    const event = expect.anything();

    findFirstWorkItemLinkChildItem().vm.$emit('click', event);

    expect(wrapper.emitted('click')).toEqual([[{ event, childItem: 'gid://gitlab/WorkItem/2' }]]);
  });

  it.each`
    description            | workItemType   | prefetch
    ${'prefetches'}        | ${'Issue'}     | ${true}
    ${'does not prefetch'} | ${'Objective'} | ${false}
  `(
    '$description work-item-link-child on mouseover when workItemType is "$workItemType"',
    async ({ workItemType, prefetch }) => {
      createComponent({ workItemType });
      findFirstWorkItemLinkChildItem().vm.$emit('mouseover', childrenWorkItems[0]);
      await nextTick();
      await waitForPromises();

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);

      if (prefetch) {
        expect(getWorkItemQueryHandler).toHaveBeenCalled();
      } else {
        expect(getWorkItemQueryHandler).not.toHaveBeenCalled();
      }
    },
  );

  it('does not render draggable component when user is not logged in', () => {
    createComponent({ canUpdate: true });

    expect(findDraggable().exists()).toBe(false);
  });

  it('disables list when `disableContent` is true', () => {
    createComponent({ disableContent: true });

    expect(findChildItemsContainer().classes('disabled-content')).toBe(true);
  });

  describe('drag & drop', () => {
    let dragParams;
    let draggedItem;

    beforeEach(() => {
      isLoggedIn.mockReturnValue(true);
      createComponent({ canUpdate: true, children: childrenWorkItemsObjectives });

      draggedItem = findFirstWorkItemLinkChildItem().element;

      dragParams = {
        oldIndex: 1,
        newIndex: 0,
        from: wrapper.element,
        to: wrapper.element,
      };
    });

    it('emits drag event with child type and adds a class `is-dragging` to document body when dragging', async () => {
      expect(document.body.classList.contains('is-dragging')).toBe(false);

      wrapper.findComponent(Draggable).vm.$emit('start', { item: draggedItem });

      expect(wrapper.emitted('drag')).toEqual([[draggedItem.dataset.childType]]);
      expect(document.body.classList.contains('is-dragging')).toBe(true);

      wrapper.findComponent(Draggable).vm.$emit('end', dragParams);
      expect(wrapper.emitted('drop').length).toBe(1);
      await nextTick();

      expect(document.body.classList.contains('is-dragging')).toBe(false);
    });

    it('dispatches `mouseup` event and cancels drag when Escape key is pressed', async () => {
      jest.spyOn(document, 'dispatchEvent');
      wrapper.findComponent(Draggable).vm.$emit('start', { item: draggedItem });

      const event = new Event('keyup');
      event.code = ESC_KEY;
      document.dispatchEvent(event);

      wrapper.findComponent(Draggable).vm.$emit('end', dragParams);
      await nextTick();

      expect(document.dispatchEvent).toHaveBeenCalledWith(new Event('mouseup'));
      expect(moveWorkItemMutationSuccessHandler).not.toHaveBeenCalled();
    });

    it('does not fetch nested children when reordering within the same work item', async () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(true);

      wrapper.findComponent(Draggable).vm.$emit('end', dragParams);
      await nextTick();

      expect(getWorkItemTreeQueryHandler).not.toHaveBeenCalled();
    });

    it('fetches nested children when moving item to another child', async () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(true);

      wrapper.findComponent(Draggable).vm.$emit('end', {
        ...dragParams,
        to: { dataset: { parentId: 'gid://gitlab/WorkItem/5', parentTitle: 'Objective 19' } },
      });
      await nextTick();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalled();
    });

    it('calls move mutation with reorder params when reordering within the same work item', async () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(true);

      wrapper.findComponent(Draggable).vm.$emit('end', dragParams);
      await waitForPromises();

      expect(moveWorkItemMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/6',
          adjacentWorkItemId: 'gid://gitlab/WorkItem/5',
          relativePosition: 'BEFORE',
        },
        endCursor: '',
        pageSize: 2, // number of children
      });
    });

    it('calls move mutation with hierarchy params when changing parent', async () => {
      expect(wrapper.findComponent(Draggable).exists()).toBe(true);

      wrapper.findComponent(Draggable).vm.$emit('end', {
        ...dragParams,
        to: { dataset: { parentId: 'gid://gitlab/WorkItem/5', parentTitle: 'Objective 19' } },
      });
      await waitForPromises();

      expect(moveWorkItemMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/6',
          parentId: 'gid://gitlab/WorkItem/5',
        },
        endCursor: '',
        pageSize: 1, // number of children
      });
    });

    it('emits error and updates cache when change parent mutation fails', async () => {
      const mockCacheUpdate = jest.spyOn(cacheUtils, 'addHierarchyChild');

      createComponent({
        canUpdate: true,
        moveWorkItemMutationHandler: moveWorkItemMutationFailureHandler,
      });

      wrapper.findComponent(Draggable).vm.$emit('end', {
        ...dragParams,
        to: { dataset: { parentId: 'gid://gitlab/WorkItem/5', parentTitle: 'Objective 19' } },
      });
      await waitForPromises();

      expect(moveWorkItemMutationFailureHandler).toHaveBeenCalled();
      expect(wrapper.emitted('error')).toEqual([['Error']]);
      expect(mockCacheUpdate).toHaveBeenCalled();
    });

    it('emits error when reorder mutation fails', async () => {
      const mockCacheUpdate = jest.spyOn(cacheUtils, 'addHierarchyChild');

      createComponent({
        canUpdate: true,
        moveWorkItemMutationHandler: moveWorkItemMutationFailureHandler,
      });

      wrapper.findComponent(Draggable).vm.$emit('end', dragParams);
      await waitForPromises();

      expect(moveWorkItemMutationFailureHandler).toHaveBeenCalled();
      expect(wrapper.emitted('error')).toEqual([['Error']]);
      expect(mockCacheUpdate).not.toHaveBeenCalled();
    });

    it('opens nested child on move', async () => {
      const mockEvt = {
        relatedContext: {
          element: childrenWorkItemsObjectives[0],
        },
      };
      const mockOriginalEvt = {
        clientX: 10,
        clientY: 10,
        target: {
          getBoundingClientRect() {
            return {
              top: 5,
              left: 5,
            };
          },
        },
      };

      wrapper.findComponent(Draggable).vm.move(mockEvt, mockOriginalEvt);

      jest.runAllTimers();
      await nextTick();

      expect(mockToggleHierarchyTreeChildResolver).toHaveBeenCalled();
    });
  });

  describe('when user is logged in', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(true);
    });

    it('renders draggable component without disabling the list', () => {
      createComponent({ canUpdate: true });

      expect(findDraggable().exists()).toBe(true);
      expect(findDraggable().classes('disabled-content')).toBe(false);
    });

    it('does not render draggable component when user has no permission', () => {
      createComponent({ canUpdate: false });

      expect(findDraggable().exists()).toBe(false);
    });

    it('disables the list when `disableContent` is true', () => {
      createComponent({ disableContent: true, canUpdate: true });

      expect(findDraggable().exists()).toBe(true);
      expect(findDraggable().classes('disabled-content')).toBe(true);
    });
  });

  describe('when removing child work item', () => {
    const workItem = { id: 'gid://gitlab/WorkItem/2' };

    describe('when successful', () => {
      beforeEach(async () => {
        createComponent();
        findFirstWorkItemLinkChildItem().vm.$emit('removeChild', workItem);
        await waitForPromises();
      });

      it('calls a mutation to update the work item', () => {
        expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
          input: {
            id: workItem.id,
            hierarchyWidget: {
              parentId: null,
            },
          },
        });
      });

      it('shows a toast', () => {
        expect($toast.show).toHaveBeenCalledWith('Child removed', {
          action: { onClick: expect.anything(), text: 'Undo' },
        });
      });
    });

    describe('when not successful', () => {
      beforeEach(async () => {
        createComponent({
          mutationHandler: jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse),
        });
        findFirstWorkItemLinkChildItem().vm.$emit('removeChild', workItem);
        await waitForPromises();
      });

      it('emits an error message', () => {
        expect(wrapper.emitted('error')).toEqual([['Something went wrong while removing child.']]);
      });
    });
  });
});
