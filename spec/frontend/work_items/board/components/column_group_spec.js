import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import ColumnGroup from '~/work_items/board/components/column_group.vue';
import ColumnHeader from '~/work_items/board/components/column_header.vue';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import WorkItemCardSkeleton from '~/work_items/board/components/work_item_card_skeleton.vue';
import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';
import { mockStatus, buildWorkItemNode, buildBoardWorkItemsResponse } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('ColumnGroup', () => {
  let wrapper;

  const boardQueryHandler = jest.fn();
  const restQueryHandler = jest.fn();

  const findColumnHeader = () => wrapper.findComponent(ColumnHeader);
  const findSkeletons = () => wrapper.findAllComponents(WorkItemCardSkeleton);
  const findWorkItemCards = () => wrapper.findAllComponents(WorkItemCard);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findErrorState = () => wrapper.findByTestId('error-state');
  const findLoadMore = () => wrapper.findComponent(WorkItemChildrenLoadMore);
  const findLoadMoreError = () => wrapper.findByTestId('load-more-error');

  const baseQueryVariables = {
    state: 'opened',
    sort: 'CREATED_DESC',
  };

  const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
    const apolloProvider = createMockApollo([
      [getBoardWorkItemsQuery, boardQueryHandler],
      [getWorkItemsRestQuery, restQueryHandler],
    ]);

    wrapper = shallowMountExtended(ColumnGroup, {
      apolloProvider,
      provide: {
        glFeatures,
      },
      propsData: {
        value: mockStatus,
        groupProperty: 'status',
        rootPageFullPath: 'full/path',
        baseQueryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
    restQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
  });

  describe('column header', () => {
    it('passes the value, groupProperty, and item count to ColumnHeader', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnHeader().props('value')).toEqual(mockStatus);
      expect(findColumnHeader().props('groupProperty')).toBe('status');
      expect(findColumnHeader().props('count')).toBe(1);
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

    it('uses groupProperty as the variable key for the grouped value', async () => {
      createComponent({ props: { groupProperty: 'customGroup' } });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          customGroup: { name: mockStatus.name },
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
    it.each([
      { workItemRestApiFrontendUsers: true, workItemRestApiIndex: true, workItemRestApi: false },
      { workItemRestApiFrontendUsers: true, workItemRestApiIndex: false, workItemRestApi: true },
      { workItemRestApiFrontendUsers: true, workItemRestApiIndex: true, workItemRestApi: true },
    ])(
      'uses getWorkItemsRestQuery when workItemRestApiFrontendUsers is enabled and either workItemRestApiIndex or workItemRestApi is enabled (flags: %o)',
      async (glFeatures) => {
        createComponent({ glFeatures });
        await waitForPromises();

        expect(restQueryHandler).toHaveBeenCalled();
        expect(boardQueryHandler).not.toHaveBeenCalled();
      },
    );

    it.each([
      { workItemRestApiFrontendUsers: true, workItemRestApiIndex: false, workItemRestApi: false },
      { workItemRestApiFrontendUsers: false, workItemRestApiIndex: true, workItemRestApi: true },
      { workItemRestApiFrontendUsers: false, workItemRestApiIndex: true, workItemRestApi: false },
      { workItemRestApiFrontendUsers: false, workItemRestApiIndex: false, workItemRestApi: true },
      { workItemRestApiFrontendUsers: false, workItemRestApiIndex: false, workItemRestApi: false },
    ])('uses getBoardWorkItemsQuery when flags are %o', async (glFeatures) => {
      createComponent({ glFeatures });
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
      expect(findColumnHeader().props('count')).toBe(4);
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
});
