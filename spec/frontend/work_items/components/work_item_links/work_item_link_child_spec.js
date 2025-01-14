import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createAlert } from '~/alert';

import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';
import isExpandedHierarchyTreeChildQuery from '~/work_items/graphql/client/is_expanded_hierarchy_tree_child.query.graphql';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemLinkChildContents from '~/work_items/components/shared/work_item_link_child_contents.vue';
import {
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_VALUE_OBJECTIVE,
  WORK_ITEM_TYPE_VALUE_TASK,
  DEFAULT_PAGE_SIZE_CHILD_ITEMS,
  WORK_ITEM_TYPE_VALUE_EPIC,
} from '~/work_items/constants';

import {
  workItemTask,
  workItemObjectiveWithChild,
  workItemObjectiveWithClosedChild,
  workItemEpic,
  workItemHierarchyTreeResponse,
  workItemHierarchyPaginatedTreeResponse,
  workItemHierarchyTreeFailureResponse,
  workItemHierarchyNoChildrenTreeResponse,
  workItemHierarchyTreeSingleClosedItemResponse,
  workItemWithParentAsChild,
} from '../../mock_data';

jest.mock('~/alert');

describe('WorkItemLinkChild', () => {
  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';
  let wrapper;
  const workItemFullPath = 'test-project-path';

  Vue.use(VueApollo);

  const findWorkItemLinkChildContents = () => wrapper.findComponent(WorkItemLinkChildContents);
  const findExpandButton = () => wrapper.findByTestId('expand-child');
  const findTreeChildren = () => wrapper.findComponent(WorkItemChildrenWrapper);
  const getWidgetHierarchy = () =>
    workItemHierarchyTreeResponse.data.workItem.widgets.find(
      (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
    );
  const getChildrenNodes = () => getWidgetHierarchy().children.nodes;
  const findFirstItem = () => getChildrenNodes()[0];
  const findWorkItemLinkChildContentsContainer = () =>
    wrapper.findByTestId('child-contents-container');

  const mockToggleHierarchyTreeChildResolver = jest.fn();
  const getWorkItemTreeQueryHandler = jest.fn().mockResolvedValue(workItemHierarchyTreeResponse);

  const createComponent = ({
    canUpdate = true,
    issuableGid = WORK_ITEM_ID,
    childItem = workItemObjectiveWithChild,
    workItemType = WORK_ITEM_TYPE_VALUE_OBJECTIVE,
    workItemTreeQueryHandler = getWorkItemTreeQueryHandler,
    isExpanded = false,
    showTaskWeight = false,
    showClosed = true,
    props = {},
  } = {}) => {
    const mockApollo = createMockApollo([[getWorkItemTreeQuery, workItemTreeQueryHandler]], {
      Mutation: {
        toggleHierarchyTreeChild: mockToggleHierarchyTreeChildResolver,
      },
    });
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: isExpandedHierarchyTreeChildQuery,
      variables: {
        id: childItem.id,
      },
      data: {
        isExpandedHierarchyTreeChild: { id: childItem.id, isExpanded },
      },
    });

    wrapper = shallowMountExtended(WorkItemLinkChild, {
      apolloProvider: mockApollo,
      propsData: {
        canUpdate,
        issuableGid,
        childItem,
        workItemType,
        workItemFullPath,
        showTaskWeight,
        showClosed,
        ...props,
      },
      stubs: {
        WorkItemChildrenWrapper,
      },
    });
  };

  beforeEach(() => {
    createAlert.mockClear();
  });

  describe('when clicking on expand button', () => {
    it('fetches and displays children of item when clicking on expand button', async () => {
      createComponent();
      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() });

      expect(findExpandButton().props('loading')).toBe(true);
      await waitForPromises();

      expect(mockToggleHierarchyTreeChildResolver).toHaveBeenCalled();
      expect(getWorkItemTreeQueryHandler).toHaveBeenCalled();
    });

    it('does not render border on `WorkItemLinkChildContents` container', async () => {
      createComponent();
      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() });

      expect(findWorkItemLinkChildContentsContainer().classes()).not.toContain('!gl-border-b-1');
    });
  });

  describe('child is already expanded', () => {
    beforeEach(async () => {
      createComponent({ isExpanded: true });
      await waitForPromises();
    });

    it('does not fetch children if already fetched once while clicking expand button', async () => {
      expect(findTreeChildren().exists()).toBe(true);
      const childrenNodes = getChildrenNodes();
      expect(findTreeChildren().props('children')).toEqual(childrenNodes);

      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() }); // Collapse
      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() }); // Expand again
      await waitForPromises();

      expect(getWorkItemTreeQueryHandler).toHaveBeenCalledTimes(1); // ensure children were fetched only once.
      expect(findTreeChildren().exists()).toBe(true);
    });

    it('renders border on `WorkItemLinkChildContents` container', () => {
      expect(findWorkItemLinkChildContentsContainer().classes()).toEqual([
        'gl-w-full',
        '!gl-border-x-0',
        '!gl-border-b-1',
        '!gl-border-t-0',
        '!gl-border-solid',
        'gl-border-default',
        '!gl-pb-2',
      ]);
    });
  });

  describe('without children', () => {
    beforeEach(() => {
      createComponent({ childItem: workItemTask, workItemType: WORK_ITEM_TYPE_VALUE_TASK });
    });

    it('does not display expand button', () => {
      expect(findExpandButton().exists()).toBe(false);
    });
  });

  describe('nested children', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays expand button when item has children, children are not displayed by default', () => {
      expect(findExpandButton().exists()).toBe(true);
      expect(findTreeChildren().exists()).toBe(false);
    });

    it('do not displays expand button when children are all closed', () => {
      createComponent({ showClosed: false, childItem: workItemObjectiveWithClosedChild });

      expect(findExpandButton().exists()).toBe(false);
    });

    it('calls createAlert when children fetch request fails on clicking expand button', async () => {
      const getWorkItemTreeQueryFailureHandler = jest
        .fn()
        .mockRejectedValue(workItemHierarchyTreeFailureResponse);

      createComponent({
        workItemTreeQueryHandler: getWorkItemTreeQueryFailureHandler,
      });

      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while fetching children.',
      });
    });

    it('click event on child emits `click` event', () => {
      createComponent({ isExpanded: true });

      findTreeChildren().vm.$emit('click', 'event');

      expect(wrapper.emitted('click')).toEqual([['event']]);
    });

    it('emits event on removing child item', () => {
      createComponent({ isExpanded: true });

      findTreeChildren().vm.$emit('removeChild', findFirstItem());

      expect(wrapper.emitted('removeChild')).toEqual([[workItemObjectiveWithChild]]);
    });

    describe('renders WorkItemLinkChildContents', () => {
      it('with default props', () => {
        createComponent();

        expect(findWorkItemLinkChildContents().props()).toEqual({
          childItem: workItemObjectiveWithChild,
          canUpdate: true,
          showLabels: true,
          workItemFullPath,
          showWeight: true,
        });
      });

      it.each`
        workItemType                      | childItem                     | showTaskWeight | showWeight
        ${WORK_ITEM_TYPE_VALUE_TASK}      | ${workItemTask}               | ${false}       | ${false}
        ${WORK_ITEM_TYPE_VALUE_TASK}      | ${workItemTask}               | ${true}        | ${true}
        ${WORK_ITEM_TYPE_VALUE_OBJECTIVE} | ${workItemObjectiveWithChild} | ${false}       | ${true}
        ${WORK_ITEM_TYPE_VALUE_OBJECTIVE} | ${workItemObjectiveWithChild} | ${true}        | ${true}
        ${WORK_ITEM_TYPE_VALUE_OBJECTIVE} | ${workItemObjectiveWithChild} | ${false}       | ${true}
        ${WORK_ITEM_TYPE_VALUE_EPIC}      | ${workItemEpic}               | ${true}        | ${true}
      `(
        'passes `showWeight` as $showWeight when the type is $workItemType and `showTaskWeight` is $showWeight',
        ({ childItem, showWeight }) => {
          createComponent({
            childItem,
            showTaskWeight: showWeight,
          });

          expect(findWorkItemLinkChildContents().props('showWeight')).toEqual(showWeight);
        },
      );
    });

    it('filters closed children', async () => {
      createComponent({
        workItemTreeQueryHandler: jest
          .fn()
          .mockRejectedValue(workItemHierarchyTreeSingleClosedItemResponse),
        workItemType: WORK_ITEM_TYPE_VALUE_OBJECTIVE,
        isExpanded: true,
      });
      await findExpandButton().vm.$emit('click', { stopPropagation: jest.fn() });

      await waitForPromises();

      expect(findTreeChildren().exists()).toBe(true);
      expect(findTreeChildren().props('children')).toHaveLength(0);
    });

    describe('pagination', () => {
      const findWorkItemChildrenLoadMore = () => wrapper.findByTestId('work-item-load-more');
      let workItemTreeQueryHandler;

      beforeEach(async () => {
        workItemTreeQueryHandler = jest
          .fn()
          .mockResolvedValue(workItemHierarchyPaginatedTreeResponse);

        createComponent({
          workItemTreeQueryHandler,
          isExpanded: true,
        });

        await waitForPromises();
      });

      it('shows work-item-children-load-more component when hasNextPage is true and node is expanded', () => {
        const loadMore = findWorkItemChildrenLoadMore();
        expect(loadMore.exists()).toBe(true);
        expect(loadMore.props('fetchNextPageInProgress')).toBe(false);
      });

      it('queries next page children when work-item-children-load-more emits "fetch-next-page"', async () => {
        findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
        await waitForPromises();

        expect(workItemTreeQueryHandler).toHaveBeenCalledWith({
          endCursor: 'Y3Vyc29yOjE=',
          id: 'gid://gitlab/WorkItem/12',
          pageSize: DEFAULT_PAGE_SIZE_CHILD_ITEMS,
        });
      });

      it('shows alert message when fetching next page fails', async () => {
        jest
          .spyOn(wrapper.vm.$apollo.queries.hierarchyWidget, 'fetchMore')
          .mockRejectedValueOnce({});
        findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: expect.any(Object),
          message: 'Something went wrong while fetching children.',
        });
      });
    });
  });

  describe('drag & drop', () => {
    const allowedChildrenByType = { Issue: ['Task'], Epic: ['Epic', 'Issue'] };
    const getWorkItemTreeNoChildrenQueryHandler = jest
      .fn()
      .mockResolvedValue(workItemHierarchyNoChildrenTreeResponse);

    it('emits drag & drop events from children wrapper', () => {
      createComponent({
        isExpanded: true,
      });

      findTreeChildren().vm.$emit('drag', 'Task');
      expect(wrapper.emitted('drag')).toEqual([['Task']]);

      findTreeChildren().vm.$emit('drop');
      expect(wrapper.emitted('drop').length).toBe(1);
    });

    it.each`
      draggedItemType | childItemType | showChildrenDropzone
      ${'Task'}       | ${'Task'}     | ${false}
      ${'Task'}       | ${'Issue'}    | ${true}
      ${'Task'}       | ${'Epic'}     | ${false}
      ${'Issue'}      | ${'Task'}     | ${false}
      ${'Issue'}      | ${'Issue'}    | ${false}
      ${'Issue'}      | ${'Epic'}     | ${true}
      ${'Epic'}       | ${'Task'}     | ${false}
      ${'Epic'}       | ${'Issue'}    | ${false}
      ${'Epic'}       | ${'Epic'}     | ${true}
    `(
      'shows children dropzone is $showChildrenDropzone when dragging $draggedItemType in $childItemType for orphans',
      async ({ draggedItemType, childItemType, showChildrenDropzone }) => {
        createComponent({
          workItemTreeQueryHandler: getWorkItemTreeNoChildrenQueryHandler,
          props: {
            allowedChildrenByType,
            draggedItemType,
            childItem: {
              ...workItemEpic,
              workItemType: {
                ...workItemEpic.workItemType,
                name: childItemType,
              },
            },
          },
        });
        await waitForPromises();

        expect(findTreeChildren().exists()).toBe(showChildrenDropzone);
      },
    );
  });

  describe('active state', () => {
    it('applies blue background when child item is active', () => {
      createComponent({
        props: {
          activeChildItemId: workItemObjectiveWithChild.id,
        },
      });

      expect(findWorkItemLinkChildContents().classes()).toContain('gl-bg-blue-50');
    });

    it('does not apply blue background when child item is not active', () => {
      createComponent({
        props: {
          activeChildItemId: 'gid://gitlab/WorkItem/3',
        },
      });

      expect(findWorkItemLinkChildContents().classes()).not.toContain('gl-bg-blue-50');
    });
  });

  describe('when parent is same as the grand child', () => {
    it('hide the expand to avoid cyclic calls', () => {
      createComponent({
        childItem: workItemWithParentAsChild,
        props: {
          parentId: 'gid://gitlab/WorkItem/1',
        },
      });

      expect(findExpandButton().exists()).toBe(false);
    });
  });
});
