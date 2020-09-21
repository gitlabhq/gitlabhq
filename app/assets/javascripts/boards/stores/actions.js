import Cookies from 'js-cookie';
import { sortBy, pick } from 'lodash';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { BoardType, ListType, inactiveId } from '~/boards/constants';
import * as types from './mutation_types';
import { formatListIssues, fullBoardId } from '../boards_util';
import boardStore from '~/boards/stores/boards_store';

import listsIssuesQuery from '../queries/lists_issues.query.graphql';
import projectBoardQuery from '../queries/project_board.query.graphql';
import groupBoardQuery from '../queries/group_board.query.graphql';
import createBoardListMutation from '../queries/board_list_create.mutation.graphql';
import updateBoardListMutation from '../queries/board_list_update.mutation.graphql';
import issueMoveListMutation from '../queries/issue_move_list.mutation.graphql';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const gqlClient = createDefaultClient();

export default {
  setInitialBoardData: ({ commit }, data) => {
    commit(types.SET_INITIAL_BOARD_DATA, data);
  },

  setActiveId({ commit }, { id, sidebarType }) {
    commit(types.SET_ACTIVE_ID, { id, sidebarType });
  },

  unsetActiveId({ dispatch }) {
    dispatch('setActiveId', { id: inactiveId, sidebarType: '' });
  },

  setFilters: ({ commit }, filters) => {
    const filterParams = pick(filters, [
      'assigneeUsername',
      'authorUsername',
      'labelName',
      'milestoneTitle',
      'releaseTag',
      'search',
    ]);
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
            doNotFetchIssues: true,
          }),
        );
        commit(types.RECEIVE_BOARD_LISTS_SUCCESS, sortBy(lists, 'position'));
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
          dispatch('addList', list);
        }
      })
      .catch(() => {
        commit(types.CREATE_LIST_FAILURE);
      });
  },

  addList: ({ state, commit }, list) => {
    const lists = state.boardLists;
    // Temporarily using positioning logic from boardStore
    lists.push(boardStore.updateListPosition({ ...list, doNotFetchIssues: true }));
    commit(types.RECEIVE_BOARD_LISTS_SUCCESS, sortBy(lists, 'position'));
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

  moveList: ({ state, commit, dispatch }, { listId, newIndex, adjustmentValue }) => {
    const { boardLists } = state;
    const backupList = [...boardLists];
    const movedList = boardLists.find(({ id }) => id === listId);

    const newPosition = newIndex - 1;
    const listAtNewIndex = boardLists[newIndex];

    movedList.position = newPosition;
    listAtNewIndex.position += adjustmentValue;
    commit(types.MOVE_LIST, {
      movedList,
      listAtNewIndex,
    });

    dispatch('updateList', { listId, position: newPosition, backupList });
  },

  updateList: ({ commit }, { listId, position, collapsed, backupList }) => {
    gqlClient
      .mutate({
        mutation: updateBoardListMutation,
        variables: {
          listId,
          position,
          collapsed,
        },
      })
      .then(({ data }) => {
        if (data?.updateBoardList?.errors.length) {
          commit(types.UPDATE_LIST_FAILURE, backupList);
        }
      })
      .catch(() => {
        commit(types.UPDATE_LIST_FAILURE, backupList);
      });
  },

  deleteList: () => {
    notImplemented();
  },

  fetchIssuesForList: ({ state, commit }, listId) => {
    const { endpoints, boardType, filterParams } = state;
    const { fullPath, boardId } = endpoints;

    const variables = {
      fullPath,
      boardId: fullBoardId(boardId),
      id: listId,
      filters: filterParams,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
    };

    return gqlClient
      .query({
        query: listsIssuesQuery,
        context: {
          isSingleRequest: true,
        },
        variables,
      })
      .then(({ data }) => {
        const { lists } = data[boardType]?.board;
        const listIssues = formatListIssues(lists);
        commit(types.RECEIVE_ISSUES_FOR_LIST_SUCCESS, { listIssues, listId });
      })
      .catch(() => commit(types.RECEIVE_ISSUES_FOR_LIST_FAILURE, listId));
  },

  resetIssues: ({ commit }) => {
    commit(types.RESET_ISSUES);
  },

  moveIssue: (
    { state, commit },
    { issueId, issueIid, issuePath, fromListId, toListId, moveBeforeId, moveAfterId },
  ) => {
    const originalIssue = state.issues[issueId];
    const fromList = state.issuesByListId[fromListId];
    const originalIndex = fromList.indexOf(Number(issueId));
    commit(types.MOVE_ISSUE, { originalIssue, fromListId, toListId, moveBeforeId, moveAfterId });

    const { boardId } = state.endpoints;
    const [fullProjectPath] = issuePath.split(/[#]/);

    gqlClient
      .mutate({
        mutation: issueMoveListMutation,
        variables: {
          projectPath: fullProjectPath,
          boardId: fullBoardId(boardId),
          iid: issueIid,
          fromListId: getIdFromGraphQLId(fromListId),
          toListId: getIdFromGraphQLId(toListId),
          moveBeforeId,
          moveAfterId,
        },
      })
      .then(({ data }) => {
        if (data?.issueMoveList?.errors.length) {
          commit(types.MOVE_ISSUE_FAILURE, { originalIssue, fromListId, toListId, originalIndex });
        } else {
          const issue = data.issueMoveList?.issue;
          commit(types.MOVE_ISSUE_SUCCESS, { issue });
        }
      })
      .catch(() =>
        commit(types.MOVE_ISSUE_FAILURE, { originalIssue, fromListId, toListId, originalIndex }),
      );
  },

  createNewIssue: () => {
    notImplemented();
  },

  addListIssue: ({ commit }, { list, issue, position }) => {
    commit(types.ADD_ISSUE_TO_LIST, { list, issue, position });
  },

  addListIssueFailure: ({ commit }, { list, issue }) => {
    commit(types.ADD_ISSUE_TO_LIST_FAILURE, { list, issue });
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
