import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';
import ColumnGroup from '~/work_items/board/components/column_group.vue';
import ColumnHeader from '~/work_items/board/components/column_header.vue';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import WorkItemCardSkeleton from '~/work_items/board/components/work_item_card_skeleton.vue';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { boardColumnQueryVariables } from '~/work_items/board/utils';
import {
  addWorkItemToColumn,
  removeWorkItemFromColumn,
} from '~/work_items/board/graphql/cache_updates';
import {
  mockStatus,
  buildWorkItemNode,
  buildBoardWorkItemsResponse,
  buildBoardWorkItemsCountResponse,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('ColumnGroup', () => {
  let wrapper;
  let apolloProvider;

  const boardQueryHandler = jest.fn();
  const restQueryHandler = jest.fn();
  const countQueryHandler = jest.fn();

  const findColumnHeader = () => wrapper.findComponent(ColumnHeader);
  const findSkeletons = () => wrapper.findAllComponents(WorkItemCardSkeleton);
  const findWorkItemCards = () => wrapper.findAllComponents(WorkItemCard);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findErrorState = () => wrapper.findByTestId('error-state');
  const findLoadMore = () => wrapper.findComponent(WorkItemChildrenLoadMore);
  const findLoadMoreError = () => wrapper.findByTestId('load-more-error');
  const findDraggable = () => wrapper.findComponent(DraggableCompat);

  const baseQueryVariables = {
    state: 'opened',
    sort: 'CREATED_DESC',
  };

  // ColumnGroup is attribute-agnostic; it only reads `columnFilter` and
  // `headerDecoration` off the strategy, so a small generic fixture stands in
  // for a real (EE-only) grouping strategy.
  const mockStrategy = {
    columnFilter: (value) => ({ status: { name: value.name } }),
    headerDecoration: (value) => ({ type: 'icon', name: value.iconName, color: value.color }),
  };

  const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
    apolloProvider = createMockApollo([
      [getBoardWorkItemsQuery, boardQueryHandler],
      [getWorkItemsRestQuery, restQueryHandler],
      [getWorkItemsCountOnlyQuery, countQueryHandler],
    ]);

    wrapper = shallowMountExtended(ColumnGroup, {
      apolloProvider,
      provide: {
        glFeatures,
      },
      propsData: {
        value: mockStatus,
        strategy: mockStrategy,
        rootPageFullPath: 'full/path',
        baseQueryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
    restQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
    countQueryHandler.mockResolvedValue(buildBoardWorkItemsCountResponse(1));
  });

  describe('column header', () => {
    it('passes the value, decoration, and item count to ColumnHeader', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnHeader().props('value')).toEqual(mockStatus);
      expect(findColumnHeader().props('decoration')).toEqual({
        type: 'icon',
        name: 'status-waiting',
        color: '#737278',
      });
      expect(findColumnHeader().props('count')).toBe(1);
    });

    it('passes the total count from the count query, not the number of loaded items', async () => {
      // A single page is loaded, but the column actually holds 57 matching items.
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
      countQueryHandler.mockResolvedValue(buildBoardWorkItemsCountResponse(57));
      createComponent();
      await waitForPromises();

      expect(findWorkItemCards()).toHaveLength(1);
      expect(findColumnHeader().props('count')).toBe(57);
    });

    it('queries the count with the column query variables', async () => {
      createComponent();
      await waitForPromises();

      expect(countQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          fullPath: 'full/path',
          ...baseQueryVariables,
          status: { name: mockStatus.name },
        }),
      );
    });

    it('captures the error in Sentry when the count query fails', async () => {
      const queryError = new Error('GraphQL failure');
      countQueryHandler.mockRejectedValue(queryError);
      createComponent();
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(queryError);
    });
  });

  describe('collapsed state', () => {
    it('is expanded by default: full-height wide column showing the card list', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnHeader().props('collapsed')).toBe(false);
      expect(findDraggable().isVisible()).toBe(true);
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-h-full', 'gl-w-48']));
    });

    it('renders a narrow, content-height strip and hides the card list when collapsed', async () => {
      createComponent({ props: { collapsed: true } });
      await waitForPromises();

      expect(findColumnHeader().props('collapsed')).toBe(true);
      // The card list stays in the DOM (so aria-controls stays valid) but is hidden.
      expect(findDraggable().isVisible()).toBe(false);
      expect(wrapper.classes()).toEqual(expect.arrayContaining(['gl-w-8', 'gl-self-start']));
      expect(wrapper.classes()).not.toContain('gl-h-full');
    });

    it('links the header collapse toggle to the card list via a shared id', async () => {
      createComponent();
      await waitForPromises();

      const controlsId = findColumnHeader().props('controlsId');

      expect(controlsId).toEqual(expect.any(String));
      expect(controlsId).not.toBe('');
      expect(findDraggable().element.closest(`#${controlsId}`)).not.toBe(null);
    });

    it('forwards toggle-collapse from the header', async () => {
      createComponent({ props: { collapsed: true } });
      await waitForPromises();

      findColumnHeader().vm.$emit('toggle-collapse');

      expect(wrapper.emitted('toggle-collapse')).toHaveLength(1);
    });

    it('does not fetch the list query when collapsed', async () => {
      createComponent({ props: { collapsed: true } });
      await waitForPromises();

      expect(boardQueryHandler).not.toHaveBeenCalled();
    });

    it('still fetches the count query when collapsed', async () => {
      createComponent({ props: { collapsed: true } });
      await waitForPromises();

      expect(countQueryHandler).toHaveBeenCalled();
      expect(findColumnHeader().props('count')).toBe(1);
    });

    it('fetches the list query once expanded after being collapsed', async () => {
      createComponent({ props: { collapsed: true } });
      await waitForPromises();

      expect(boardQueryHandler).not.toHaveBeenCalled();

      await wrapper.setProps({ collapsed: false });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalled();
      expect(findWorkItemCards()).toHaveLength(1);
    });
  });

  describe('while loading the initial page', () => {
    it('renders skeleton ghost cards and no real cards or empty state', () => {
      createComponent();

      expect(findSkeletons()).toHaveLength(3);
      expect(findWorkItemCards()).toHaveLength(0);
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when no work items are returned', () => {
    beforeEach(async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      createComponent();
      await waitForPromises();
    });

    it('hides the skeleton ghost cards', () => {
      expect(findSkeletons()).toHaveLength(0);
    });

    it('renders the empty state message', () => {
      expect(findEmptyState().text()).toBe('No items');
    });

    it('does not render any work item cards', () => {
      expect(findWorkItemCards()).toHaveLength(0);
    });

    it('still renders the draggable drop zone so items can be dropped into the column', () => {
      expect(findDraggable().exists()).toBe(true);
    });
  });

  describe('when work items are returned', () => {
    const nodes = [buildWorkItemNode(1), buildWorkItemNode(2), buildWorkItemNode(3)];

    beforeEach(async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse(nodes));
      createComponent();
      await waitForPromises();
    });

    it('renders one WorkItemCard per node', () => {
      expect(findWorkItemCards()).toHaveLength(nodes.length);
    });

    it('passes each work item to its card', () => {
      const renderedItems = findWorkItemCards().wrappers.map((card) => card.props('item'));
      expect(renderedItems).toEqual(nodes);
    });

    it('does not render the empty state or skeleton ghost cards', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findSkeletons()).toHaveLength(0);
    });
  });

  describe('drag and drop', () => {
    const nodes = [buildWorkItemNode(1), buildWorkItemNode(2)];

    beforeEach(async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse(nodes));
      createComponent();
      await waitForPromises();
    });

    it('binds the work items to a shared draggable group keyed by id', () => {
      expect(findDraggable().props('value')).toEqual(nodes);
      expect(findDraggable().props('itemKey')).toBe('id');
      expect(findDraggable().vm.$attrs.group).toEqual({ name: 'work-item-board', put: true });
      expect(findDraggable().attributes('tag')).toBe('ul');
      expect(findDraggable().attributes('data-group-value-id')).toBe(mockStatus.id);
    });

    it('emits card-move with the drag event when a card is dropped', () => {
      const dragEvent = { oldIndex: 0, newIndex: 1 };
      findDraggable().vm.$emit('end', dragEvent);

      expect(wrapper.emitted('card-move')).toEqual([[dragEvent]]);
    });

    it('does not disable the draggable by default', () => {
      expect(findDraggable().attributes('disabled')).toBeUndefined();
    });

    it('disables the draggable while dragDisabled is true', async () => {
      createComponent({ props: { dragDisabled: true } });
      await waitForPromises();

      expect(findDraggable().attributes('disabled')).toBeDefined();
    });
  });

  describe('drop-disabled column', () => {
    it('keeps put enabled and the column un-dimmed by default', async () => {
      createComponent();
      await waitForPromises();

      expect(findDraggable().vm.$attrs.group).toEqual({ name: 'work-item-board', put: true });
      expect(wrapper.classes()).not.toContain('gl-opacity-5');
    });

    it('disables put and dims the column when dropDisabled is true', async () => {
      createComponent({ props: { dropDisabled: true } });
      await waitForPromises();

      expect(findDraggable().vm.$attrs.group).toEqual({ name: 'work-item-board', put: false });
      expect(wrapper.classes()).toEqual(
        expect.arrayContaining(['gl-opacity-5', 'gl-cursor-not-allowed']),
      );
    });

    it('emits drag-start with the dragged work item node', async () => {
      createComponent();
      await waitForPromises();

      findDraggable().vm.$emit('start', {
        item: { dataset: { workItemId: 'gid://gitlab/WorkItem/1' } },
      });

      expect(wrapper.emitted('drag-start')).toHaveLength(1);
      expect(wrapper.emitted('drag-start')[0][0].id).toBe('gid://gitlab/WorkItem/1');
    });
  });

  describe('query variables', () => {
    it('passes firstPageSize, fullPath, base variables, and grouped value', async () => {
      createComponent();
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          firstPageSize: 20,
          fullPath: 'full/path',
          ...baseQueryVariables,
          status: { name: mockStatus.name },
        }),
      );
    });

    it('uses the strategy columnFilter for the grouped value variables', async () => {
      const strategy = {
        ...mockStrategy,
        columnFilter: () => ({ customGroup: { name: 'Custom' } }),
      };
      createComponent({ props: { strategy } });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          customGroup: { name: 'Custom' },
        }),
      );
    });

    it('overrides base variables that collide with the grouped value key', async () => {
      createComponent({
        props: {
          baseQueryVariables: { ...baseQueryVariables, status: { name: 'should-be-overridden' } },
        },
      });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          status: { name: mockStatus.name },
        }),
      );
    });
  });

  describe('query selection by feature flags', () => {
    it('uses getWorkItemsRestQuery when workItemRestApiFrontendUsers is enabled', async () => {
      createComponent({ glFeatures: { workItemRestApiFrontendUsers: true } });
      await waitForPromises();

      expect(restQueryHandler).toHaveBeenCalled();
      expect(boardQueryHandler).not.toHaveBeenCalled();
    });

    it('uses getBoardWorkItemsQuery when workItemRestApiFrontendUsers is disabled', async () => {
      createComponent({ glFeatures: { workItemRestApiFrontendUsers: false } });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalled();
      expect(restQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when the work items query errors', () => {
    const queryError = new Error('GraphQL failure');

    beforeEach(async () => {
      boardQueryHandler.mockRejectedValue(queryError);
      createComponent();
      await waitForPromises();
    });

    it('renders the error message', () => {
      expect(findErrorState().text()).toBe(
        'An error occurred while fetching work items for this column.',
      );
    });

    it('captures the error in Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(queryError);
    });

    it('does not render the skeleton, empty state, or work item cards', () => {
      expect(findSkeletons()).toHaveLength(0);
      expect(findEmptyState().exists()).toBe(false);
      expect(findWorkItemCards()).toHaveLength(0);
    });

    it('clears the error when the query subsequently succeeds', async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
      wrapper.vm.$apollo.queries.workItemsConnection.refetch();
      await waitForPromises();

      expect(findErrorState().exists()).toBe(false);
      expect(findWorkItemCards()).toHaveLength(1);
    });
  });

  describe('pagination', () => {
    it('does not render the load more button when there is no next page', async () => {
      boardQueryHandler.mockResolvedValue(
        buildBoardWorkItemsResponse([buildWorkItemNode(1)], { hasNextPage: false }),
      );
      createComponent();
      await waitForPromises();

      expect(findLoadMore().exists()).toBe(false);
    });

    it('renders the load more button when there is a next page', async () => {
      boardQueryHandler.mockResolvedValue(
        buildBoardWorkItemsResponse([buildWorkItemNode(1)], {
          hasNextPage: true,
          endCursor: 'CURSOR1',
        }),
      );
      createComponent();
      await waitForPromises();

      expect(findLoadMore().exists()).toBe(true);
    });

    it('fetches the next page with the end cursor and subsequent page size', async () => {
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(1)], {
          hasNextPage: true,
          endCursor: 'CURSOR1',
        }),
      );
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(2)], { hasNextPage: false }),
      );
      createComponent();
      await waitForPromises();

      findLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenLastCalledWith(
        expect.objectContaining({
          afterCursor: 'CURSOR1',
          firstPageSize: 100,
        }),
      );
    });

    it('appends the next page of work items to the existing list', async () => {
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(1), buildWorkItemNode(2)], {
          hasNextPage: true,
          endCursor: 'CURSOR1',
        }),
      );
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(3), buildWorkItemNode(4)], {
          hasNextPage: false,
        }),
      );
      createComponent();
      await waitForPromises();

      findLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(findWorkItemCards()).toHaveLength(4);
      expect(findLoadMore().exists()).toBe(false);
    });

    it('shows skeleton ghost cards after existing items and hides the load more button while paginating', async () => {
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(1)], {
          hasNextPage: true,
          endCursor: 'CURSOR1',
        }),
      );
      let resolveSecondPage;
      boardQueryHandler.mockReturnValueOnce(
        new Promise((resolve) => {
          resolveSecondPage = resolve;
        }),
      );
      createComponent();
      await waitForPromises();

      findLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(findSkeletons()).toHaveLength(3);
      expect(findWorkItemCards()).toHaveLength(1);
      expect(findLoadMore().exists()).toBe(false);

      resolveSecondPage(
        buildBoardWorkItemsResponse([buildWorkItemNode(2)], { hasNextPage: false }),
      );
      await waitForPromises();

      expect(findSkeletons()).toHaveLength(0);
    });

    describe('when fetching the next page fails', () => {
      const queryError = new Error('GraphQL failure');

      beforeEach(async () => {
        boardQueryHandler.mockResolvedValueOnce(
          buildBoardWorkItemsResponse([buildWorkItemNode(1)], {
            hasNextPage: true,
            endCursor: 'CURSOR1',
          }),
        );
        boardQueryHandler.mockRejectedValueOnce(queryError);
        createComponent();
        await waitForPromises();

        findLoadMore().vm.$emit('fetch-next-page');
        await waitForPromises();
      });

      it('renders the inline load-more error and keeps loaded items visible', () => {
        expect(findLoadMoreError().text()).toBe(
          'An error occurred while fetching more work items.',
        );
        expect(findWorkItemCards()).toHaveLength(1);
      });

      it('captures the error in Sentry', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(queryError);
      });

      it('resets the in-progress state', () => {
        expect(findLoadMore().props('fetchNextPageInProgress')).toBe(false);
      });
    });
  });

  describe('drag and drop after pagination', () => {
    // The drag-and-drop cache updates in board_view.vue key off the initial-page
    // variables (boardColumnQueryVariables) — the same entry fetchMore merges
    // subsequent pages into. After loading a second page these tests run the real
    // cache helpers against that key to prove the move lands on the merged column.
    const columnVariables = () =>
      boardColumnQueryVariables({
        rootPageFullPath: 'full/path',
        baseQueryVariables,
        columnFilter: mockStrategy.columnFilter(mockStatus),
      });
    const cachedNodeIds = () => {
      const { cache } = apolloProvider.defaultClient;
      const data = cache.readQuery({ query: getBoardWorkItemsQuery, variables: columnVariables() });
      return data.namespace.workItems.nodes.map((node) => node.id);
    };

    // nodes 1 and 2 in the first page, nodes 3 and 4 in the second page.
    beforeEach(async () => {
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(1), buildWorkItemNode(2)], {
          hasNextPage: true,
          endCursor: 'CURSOR1',
        }),
      );
      boardQueryHandler.mockResolvedValueOnce(
        buildBoardWorkItemsResponse([buildWorkItemNode(3), buildWorkItemNode(4)], {
          hasNextPage: false,
        }),
      );
      createComponent();
      await waitForPromises();

      findLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();
    });

    it('binds the full merged list to the draggable so drops resolve against every loaded page', () => {
      expect(
        findDraggable()
          .props('value')
          .map((node) => node.id),
      ).toEqual([
        'gid://gitlab/WorkItem/1',
        'gid://gitlab/WorkItem/2',
        'gid://gitlab/WorkItem/3',
        'gid://gitlab/WorkItem/4',
      ]);
    });

    it('keeps the paginated column a drop target keyed by its value id', () => {
      expect(findDraggable().attributes('data-group-value-id')).toBe(mockStatus.id);
    });

    it('removes a card on a later page', () => {
      removeWorkItemFromColumn({
        cache: apolloProvider.defaultClient.cache,
        query: getBoardWorkItemsQuery,
        variables: columnVariables(),
        workItemId: 'gid://gitlab/WorkItem/3',
      });

      expect(cachedNodeIds()).toEqual([
        'gid://gitlab/WorkItem/1',
        'gid://gitlab/WorkItem/2',
        'gid://gitlab/WorkItem/4',
      ]);
    });

    it('inserts a card past the first page', () => {
      addWorkItemToColumn({
        cache: apolloProvider.defaultClient.cache,
        query: getBoardWorkItemsQuery,
        variables: columnVariables(),
        workItem: buildWorkItemNode(5),
        index: 4,
      });

      expect(cachedNodeIds()).toEqual([
        'gid://gitlab/WorkItem/1',
        'gid://gitlab/WorkItem/2',
        'gid://gitlab/WorkItem/3',
        'gid://gitlab/WorkItem/4',
        'gid://gitlab/WorkItem/5',
      ]);
    });
  });
});
