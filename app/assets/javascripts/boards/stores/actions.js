import Cookies from 'js-cookie';
import { sortBy } from 'lodash';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { BoardType, ListType } from '~/boards/constants';
import * as types from './mutation_types';
import { formatListIssues, fullBoardId } from '../boards_util';
import boardStore from '~/boards/stores/boards_store';

import groupListsIssuesQuery from '../queries/group_lists_issues.query.graphql';
import projectListsIssuesQuery from '../queries/project_lists_issues.query.graphql';
import projectBoardQuery from '../queries/project_board.query.graphql';
import groupBoardQuery from '../queries/group_board.query.graphql';
import createBoardListMutation from '../queries/board_list_create.mutation.graphql';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const gqlClient = createDefaultClient();

export default {
  setInitialBoardData: ({ commit }, data) => {
    commit(types.SET_INITIAL_BOARD_DATA, data);
  },

  setActiveId({ commit }, id) {
    commit(types.SET_ACTIVE_ID, id);
  },

  setFilters: ({ commit }, filters) => {
    const { scope, utf8, state, ...filterParams } = filters;
    commit(types.SET_FILTERS, filterParams);
  },

  fetchLists: ({ commit, state, dispatch }) => {
    const { endpoints, boardType } = state;
    const { fullPath, boardId } = endpoints;

    let query;
    if (boardType === BoardType.group) {
      query = groupBoardQuery;
    } else if (boardType === BoardType.project) {
      query = projectBoardQuery;
    } else {
      createFlash(__('Invalid board'));
      return Promise.reject();
    }

    const variables = {
      fullPath,
      boardId: fullBoardId(boardId),
    };

    return gqlClient
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        let { lists } = data[boardType]?.board;
        // Temporarily using positioning logic from boardStore
        lists = lists.nodes.map(list =>
          boardStore.updateListPosition({
            ...list,
            id: getIdFromGraphQLId(list.id),
          }),
        );
        commit(types.RECEIVE_LISTS, sortBy(lists, 'position'));
        // Backlog list needs to be created if it doesn't exist
        if (!lists.find(l => l.type === ListType.backlog)) {
          dispatch('createList', { backlog: true });
        }
        dispatch('showWelcomeList');
      })
      .catch(() => {
        createFlash(
          __('An error occurred while fetching the board lists. Please reload the page.'),
        );
      });
  },

  // This action only supports backlog list creation at this stage
  // Future iterations will add the ability to create other list types
  createList: ({ state, commit, dispatch }, { backlog = false }) => {
    const { boardId } = state.endpoints;
    gqlClient
      .mutate({
        mutation: createBoardListMutation,
        variables: {
          boardId: fullBoardId(boardId),
          backlog,
        },
      })
      .then(({ data }) => {
        if (data?.boardListCreate?.errors.length) {
          commit(types.CREATE_LIST_FAILURE);
        } else {
          const list = data.boardListCreate?.list;
          dispatch('addList', { ...list, id: getIdFromGraphQLId(list.id) });
        }
      })
      .catch(() => {
        commit(types.CREATE_LIST_FAILURE);
      });
  },

  addList: ({ state, commit }, list) => {
    const lists = state.boardLists;
    // Temporarily using positioning logic from boardStore
    lists.push(boardStore.updateListPosition(list));
    commit(types.RECEIVE_LISTS, sortBy(lists, 'position'));
  },

  showWelcomeList: ({ state, dispatch }) => {
    if (state.disabled) {
      return;
    }
    if (
      state.boardLists.find(list => list.type !== ListType.backlog && list.type !== ListType.closed)
    ) {
      return;
    }
    if (parseBoolean(Cookies.get('issue_board_welcome_hidden'))) {
      return;
    }

    dispatch('addList', {
      id: 'blank',
      listType: ListType.blank,
      title: __('Welcome to your issue board!'),
      position: 0,
    });
  },

  showPromotionList: () => {},

  generateDefaultLists: () => {
    notImplemented();
  },

  updateList: () => {
    notImplemented();
  },

  deleteList: () => {
    notImplemented();
  },

  fetchIssuesForList: () => {
    notImplemented();
  },

  fetchIssuesForAllLists: ({ state, commit }) => {
    commit(types.REQUEST_ISSUES_FOR_ALL_LISTS);

    const { endpoints, boardType } = state;
    const { fullPath, boardId } = endpoints;

    const query = boardType === BoardType.group ? groupListsIssuesQuery : projectListsIssuesQuery;

    const variables = {
      fullPath,
      boardId: fullBoardId(boardId),
    };

    return gqlClient
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        const { lists } = data[boardType]?.board;
        const listIssues = formatListIssues(lists);
        commit(types.RECEIVE_ISSUES_FOR_ALL_LISTS_SUCCESS, listIssues);
      })
      .catch(() => commit(types.RECEIVE_ISSUES_FOR_ALL_LISTS_FAILURE));
  },

  moveIssue: () => {
    notImplemented();
  },

  createNewIssue: () => {
    notImplemented();
  },

  fetchBacklog: () => {
    notImplemented();
  },

  bulkUpdateIssues: () => {
    notImplemented();
  },

  fetchIssue: () => {
    notImplemented();
  },

  toggleIssueSubscription: () => {
    notImplemented();
  },

  showPage: () => {
    notImplemented();
  },

  toggleEmptyState: () => {
    notImplemented();
  },
};
