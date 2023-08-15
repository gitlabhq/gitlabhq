import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardApp from '~/boards/components/board_app.vue';
import eventHub from '~/boards/eventhub';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { rawIssue, boardListsQueryResponse } from '../mock_data';

describe('BoardApp', () => {
  let wrapper;
  let store;
  let mockApollo;

  const errorMessage = 'Failed to fetch lists';
  const boardListQueryHandler = jest.fn().mockResolvedValue(boardListsQueryResponse);
  const boardListQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));

  Vue.use(Vuex);
  Vue.use(VueApollo);

  const createStore = ({ mockGetters = {} } = {}) => {
    store = new Vuex.Store({
      state: {},
      actions: {
        performSearch: jest.fn(),
      },
      getters: {
        isSidebarOpen: () => true,
        ...mockGetters,
      },
    });
  };

  const createComponent = ({
    isApolloBoard = false,
    issue = rawIssue,
    handler = boardListQueryHandler,
  } = {}) => {
    mockApollo = createMockApollo([[boardListsQuery, handler]]);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: issue,
      },
    });

    wrapper = shallowMount(BoardApp, {
      apolloProvider: mockApollo,
      store,
      provide: {
        fullPath: 'gitlab-org',
        initialBoardId: 'gid://gitlab/Board/1',
        initialFilterParams: {},
        issuableType: 'issue',
        boardType: 'group',
        isIssueBoard: true,
        isGroupBoard: true,
        isApolloBoard,
      },
    });
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  afterEach(() => {
    store = null;
  });

  it("should have 'is-compact' class when sidebar is open", () => {
    createStore();
    createComponent();

    expect(wrapper.classes()).toContain('is-compact');
  });

  it("should not have 'is-compact' class when sidebar is closed", () => {
    createStore({ mockGetters: { isSidebarOpen: () => false } });
    createComponent();

    expect(wrapper.classes()).not.toContain('is-compact');
  });

  describe('Apollo boards', () => {
    beforeEach(async () => {
      createComponent({ isApolloBoard: true });
      await nextTick();
    });

    it('fetches lists', () => {
      expect(boardListQueryHandler).toHaveBeenCalled();
    });

    it('should have is-compact class when a card is selected', () => {
      expect(wrapper.classes()).toContain('is-compact');
    });

    it('should not have is-compact class when no card is selected', async () => {
      createComponent({ isApolloBoard: true, issue: {} });
      await nextTick();

      expect(wrapper.classes()).not.toContain('is-compact');
    });

    it('refetches lists when updateBoard event is received', async () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createComponent({ isApolloBoard: true });
      await waitForPromises();

      expect(eventHub.$on).toHaveBeenCalledWith('updateBoard', wrapper.vm.refetchLists);
    });

    it('sets error on fetch lists failure', async () => {
      createComponent({ isApolloBoard: true, handler: boardListQueryHandlerFailure });

      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });
});
