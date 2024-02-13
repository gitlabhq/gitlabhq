import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';

import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemTreeChildren from '~/work_items/components/work_item_links/work_item_tree_children.vue';
import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';
import {
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
} from '~/work_items/constants';

import {
  workItemTask,
  workItemObjectiveWithChild,
  workItemHierarchyTreeResponse,
  workItemHierarchyTreeFailureResponse,
  changeIndirectWorkItemParentMutationResponse,
  workItemUpdateFailureResponse,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChild', () => {
  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';
  let wrapper;
  const workItemFullPath = 'test-project-path';
  let getWorkItemTreeQueryHandler;
  let mutationChangeParentHandler;

  const $toast = {
    show: jest.fn(),
    hide: jest.fn(),
  };

  Vue.use(VueApollo);

  const findWorkItemLinkChildContents = () => wrapper.findComponent(WorkItemLinkChildContents);

  const createComponent = ({
    canUpdate = true,
    issuableGid = WORK_ITEM_ID,
    childItem = workItemTask,
    workItemType = WORK_ITEM_TYPE_VALUE_TASK,
    apolloProvider = null,
  } = {}) => {
    getWorkItemTreeQueryHandler = jest.fn().mockResolvedValue(workItemHierarchyTreeResponse);
    mutationChangeParentHandler = jest
      .fn()
      .mockResolvedValue(changeIndirectWorkItemParentMutationResponse);

    wrapper = shallowMountExtended(WorkItemLinkChild, {
      apolloProvider:
        apolloProvider ||
        createMockApollo([
          [getWorkItemTreeQuery, getWorkItemTreeQueryHandler],
          [updateWorkItemMutation, mutationChangeParentHandler],
        ]),
      propsData: {
        canUpdate,
        issuableGid,
        childItem,
        workItemType,
        workItemFullPath,
      },
      mocks: {
        $toast,
      },
    });
  };

  beforeEach(() => {
    createAlert.mockClear();
  });

  describe('renders WorkItemLinkChildContents', () => {
    beforeEach(() => {
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });
    });

    it('with default props', () => {
      expect(findWorkItemLinkChildContents().props()).toEqual({
        childItem: workItemObjectiveWithChild,
        canUpdate: true,
        showLabels: true,
        workItemFullPath,
      });
    });
  });

  describe('nested children', () => {
    const findExpandButton = () => wrapper.findByTestId('expand-child');
    const findTreeChildren = () => wrapper.findComponent(WorkItemTreeChildren);

    const getWidgetHierarchy = () =>
      workItemHierarchyTreeResponse.data.workItem.widgets.find(
        (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
      );
    const getChildrenNodes = () => getWidgetHierarchy().children.nodes;
    const findFirstItem = () => getChildrenNodes()[0];

    beforeEach(() => {
      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
      });
    });

    it('displays expand button when item has children, children are not displayed by default', () => {
      expect(findExpandButton().exists()).toBe(true);
      expect(findTreeChildren().exists()).toBe(false);
    });

    it('fetches and displays children of item when clicking on expand button', async () => {
      await findExpandButton().vm.$emit('click');

      expect(findExpandButton().props('loading')).toBe(true);
      await waitForPromises();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalled();
      expect(findTreeChildren().exists()).toBe(true);

      const childrenNodes = getChildrenNodes();
      expect(findTreeChildren().props('children')).toEqual(childrenNodes);
    });

    it('does not fetch children if already fetched once while clicking expand button', async () => {
      findExpandButton().vm.$emit('click'); // Expand for the first time
      await waitForPromises();

      expect(findTreeChildren().exists()).toBe(true);

      await findExpandButton().vm.$emit('click'); // Collapse
      findExpandButton().vm.$emit('click'); // Expand again
      await waitForPromises();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalledTimes(1); // ensure children were fetched only once.
      expect(findTreeChildren().exists()).toBe(true);
    });

    it('calls createAlert when children fetch request fails on clicking expand button', async () => {
      const getWorkItemTreeQueryFailureHandler = jest
        .fn()
        .mockRejectedValue(workItemHierarchyTreeFailureResponse);
      const apolloProvider = createMockApollo([
        [getWorkItemTreeQuery, getWorkItemTreeQueryFailureHandler],
      ]);

      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        apolloProvider,
      });

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while fetching children.',
      });
    });

    it('click event on child emits `click` event', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('click', 'event');

      expect(wrapper.emitted('click')).toEqual([['event']]);
    });

    it('shows toast on removing child item', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Child removed', {
        action: { onClick: expect.any(Function), text: 'Undo' },
      });
    });

    it('renders correct number of children after the removal', async () => {
      findExpandButton().vm.$emit('click');
      await waitForPromises();

      const childrenNodes = getChildrenNodes();
      expect(findTreeChildren().props('children')).toEqual(childrenNodes);

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect(findTreeChildren().props('children')).toEqual([]);
    });

    it('calls correct mutation with correct variables', async () => {
      const firstItem = findFirstItem();

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', firstItem);

      expect(mutationChangeParentHandler).toHaveBeenCalledWith({
        input: {
          id: firstItem.id,
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
    });

    it('shows the alert when workItem update fails', async () => {
      mutationChangeParentHandler = jest.fn().mockRejectedValue(workItemUpdateFailureResponse);
      const apolloProvider = createMockApollo([
        [getWorkItemTreeQuery, getWorkItemTreeQueryHandler],
        [updateWorkItemMutation, mutationChangeParentHandler],
      ]);

      createComponent({
        childItem: workItemObjectiveWithChild,
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        apolloProvider,
      });

      findExpandButton().vm.$emit('click');
      await waitForPromises();

      findTreeChildren().vm.$emit('removeChild', findFirstItem());
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while removing child.',
      });
    });
  });
});
