import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BoardView from '~/work_items/board/board_view.vue';
import ColumnGroup from '~/work_items/board/components/column_group.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import * as grouping from '~/work_items/board/grouping';
import { addWorkItemToColumn } from '~/work_items/board/graphql/cache_updates';
import workItemsGroupByVisibleGroupsQuery from '~/work_items/board/grouping/graphql/client/visible_groups.query.graphql';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import {
  buildNamespaceStatusesResponse,
  buildWorkItemTypesResponse,
  buildBoardRestWorkItemsResponse,
  buildBoardWorkItemsResponse,
  buildWorkItemNode,
  mockStatus,
} from './mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/work_items/board/graphql/cache_updates');

const { groupingStrategyFor } = grouping;

Vue.use(VueApollo);

describe('BoardView', () => {
  let wrapper;

  const groupByValuesHandler = jest.fn();
  const gateDataHandler = jest.fn();
  // The column-values and gate queries differ by edition (a placeholder in CE,
  // the status queries in EE), so take them from the strategy the board actually uses.
  const { valuesQuery: groupByValuesQuery, gateQuery } = groupingStrategyFor('status');

  const queryVariables = { state: 'opened', sort: 'CREATED_DESC' };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findColumnGroups = () => wrapper.findAllComponents(ColumnGroup);

  let apolloProvider;

  const createComponent = ({
    props = {},
    visibleGroups = null,
    glFeatures = {},
    handlers = [],
  } = {}) => {
    apolloProvider = createMockApollo([
      [groupByValuesQuery, groupByValuesHandler],
      ...(gateQuery ? [[gateQuery, gateDataHandler]] : []),
      ...handlers,
    ]);
    apolloProvider.clients.defaultClient.writeQuery({
      query: workItemsGroupByVisibleGroupsQuery,
      // `hydrated: true` by default so the query fires immediately, matching
      // the common case in tests below that aren't specifically about hydration.
      data: {
        workItemsGroupByVisibleGroups: visibleGroups,
        workItemsGroupByVisibleGroupsHydrated: true,
      },
    });

    wrapper = shallowMountExtended(BoardView, {
      apolloProvider,
      provide: {
        glFeatures,
      },
      propsData: {
        rootPageFullPath: 'full/path',
        queryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    groupByValuesHandler.mockResolvedValue(buildNamespaceStatusesResponse([]));
    gateDataHandler.mockResolvedValue(buildWorkItemTypesResponse());
  });

  // Statuses are an EE-only field, so grouping by status produces no columns in
  // CE (the placeholder strategy extracts none), and the board degrades
  // gracefully.
  describe('grouping by status', () => {
    it('renders no column groups', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnGroups()).toHaveLength(0);
    });

    it('renders no loading icon once settled', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('reports no error', async () => {
      createComponent();
      await waitForPromises();

      expect(Sentry.captureException).not.toHaveBeenCalled();
      expect(wrapper.emitted('set-error')).toBeUndefined();
    });
  });

  describe('when a work item is created on the board', () => {
    const createdWorkItem = buildWorkItemNode(42);

    const requestCreate = async () => {
      wrapper.findComponent(ColumnGroup).vm.$emit('create-item', mockStatus);
      await waitForPromises();
      wrapper.findComponent(CreateWorkItemModal).vm.$emit('work-item-created', createdWorkItem);
      await waitForPromises();
    };

    beforeEach(() => {
      jest.spyOn(grouping, 'groupingStrategyFor').mockReturnValue({
        property: 'status',
        valuesQuery: groupByValuesQuery,
        extractValues: () => [mockStatus],
        columnFilter: (value) => ({ status: { name: value.name } }),
        headerDecoration: () => ({ type: 'none' }),
        moveInput: () => ({}),
        newItemDraft: () => ({}),
        patchCard: () => {},
        itemValueId: () => mockStatus.id,
      });
      groupByValuesHandler.mockResolvedValue(buildNamespaceStatusesResponse([mockStatus]));
    });

    it('inserts the created item using the REST query when the flag is enabled', async () => {
      const restQueryHandler = jest
        .fn()
        .mockResolvedValue(buildBoardRestWorkItemsResponse([createdWorkItem]));
      createComponent({
        glFeatures: { workItemRestApiFrontendUsers: true },
        handlers: [[getWorkItemsRestQuery, restQueryHandler]],
      });
      await waitForPromises();

      await requestCreate();

      expect(addWorkItemToColumn).toHaveBeenCalledWith(
        expect.objectContaining({ query: getWorkItemsRestQuery, useRestApi: true }),
      );
    });

    it('inserts the created item using the GraphQL query when the flag is disabled', async () => {
      const boardQueryHandler = jest
        .fn()
        .mockResolvedValue(buildBoardWorkItemsResponse([createdWorkItem]));
      createComponent({
        glFeatures: { workItemRestApiFrontendUsers: false },
        handlers: [[getBoardWorkItemsQuery, boardQueryHandler]],
      });
      await waitForPromises();

      await requestCreate();

      expect(addWorkItemToColumn).toHaveBeenCalledWith(
        expect.objectContaining({ query: getBoardWorkItemsQuery, useRestApi: false }),
      );
    });
  });

  describe('fetch scoping', () => {
    describe('when the store has not hydrated', () => {
      beforeEach(() => {
        const scopedApolloProvider = createMockApollo([[groupByValuesQuery, groupByValuesHandler]]);
        scopedApolloProvider.clients.defaultClient.writeQuery({
          query: workItemsGroupByVisibleGroupsQuery,
          data: {
            workItemsGroupByVisibleGroups: null,
            workItemsGroupByVisibleGroupsHydrated: false,
          },
        });

        wrapper = shallowMountExtended(BoardView, {
          apolloProvider: scopedApolloProvider,
          propsData: { rootPageFullPath: 'full/path', queryVariables },
        });
      });

      it('does not fetch the group values', () => {
        expect(groupByValuesHandler).not.toHaveBeenCalled();
      });
    });

    describe('when visibleGroups is null', () => {
      beforeEach(async () => {
        createComponent({ visibleGroups: null });
        await waitForPromises();
      });

      it('omits ids, fetching everything', () => {
        expect(groupByValuesHandler).toHaveBeenCalledWith({
          fullPath: 'full/path',
          ids: undefined,
        });
      });
    });

    describe('when an explicit list is configured', () => {
      beforeEach(async () => {
        createComponent({ visibleGroups: ['status:1', 'status:2'] });
        await waitForPromises();
      });

      it('fetches only the visible ids', () => {
        expect(groupByValuesHandler).toHaveBeenCalledWith({
          fullPath: 'full/path',
          ids: ['1', '2'],
        });
      });
    });
  });
});
