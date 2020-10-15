import Cookies from 'js-cookie';
import { pick } from 'lodash';
import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { BoardType, ListType, inactiveId } from '~/boards/constants';
import * as types from './mutation_types';
import {
  formatBoardLists,
  formatListIssues,
  fullBoardId,
  formatListsPageInfo,
} from '../boards_util';
import boardStore from '~/boards/stores/boards_store';

import listsIssuesQuery from '../queries/lists_issues.query.graphql';
import boardListsQuery from '../queries/board_lists.query.graphql';
import createBoardListMutation from '../queries/board_list_create.mutation.graphql';
import updateBoardListMutation from '../queries/board_list_update.mutation.graphql';
import issueMoveListMutation from '../queries/issue_move_list.mutation.graphql';
import issueSetLabels from '../queries/issue_set_labels.mutation.graphql';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const gqlClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

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
    const { endpoints, boardType, filterParams } = state;
    const { fullPath, boardId } = endpoints;

    const variables = {
      fullPath,
      boardId: fullBoardId(boardId),
      filters: filterParams,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
    };

    return gqlClient
      .query({
        query: boardListsQuery,
        variables,
      })
      .then(({ data }) => {
        const { lists } = data[boardType]?.board;
        commit(types.RECEIVE_BOARD_LISTS_SUCCESS, formatBoardLists(lists));
        // Backlog list needs to be created if it doesn't exist
        if (!lists.nodes.find(l => l.listType === ListType.backlog)) {
          dispatch('createList', { backlog: true });
        }
        dispatch('showWelcomeList');
      })
      .catch(() => commit(types.RECEIVE_BOARD_LISTS_FAILURE));
  },

  createList: ({ state, commit, dispatch }, { backlog, labelId, milestoneId, assigneeId }) => {
    const { boardId } = state.endpoints;

    gqlClient
      .mutate({
        mutation: createBoardListMutation,
        variables: {
          boardId: fullBoardId(boardId),
          backlog,
          labelId,
          milestoneId,
          assigneeId,
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
      .catch(() => commit(types.CREATE_LIST_FAILURE));
  },

  addList: ({ commit }, list) => {
    // Temporarily using positioning logic from boardStore
    commit(
      types.RECEIVE_ADD_LIST_SUCCESS,
      boardStore.updateListPosition({ ...list, doNotFetchIssues: true }),
    );
  },

  showWelcomeList: ({ state, dispatch }) => {
    if (state.disabled) {
      return;
    }
    if (
      Object.entries(state.boardLists).find(
        ([, list]) => list.type !== ListType.backlog && list.type !== ListType.closed,
      )
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

  moveList: (
    { state, commit, dispatch },
    { listId, replacedListId, newIndex, adjustmentValue },
  ) => {
    const { boardLists } = state;
    const backupList = { ...boardLists };
    const movedList = boardLists[listId];

    const newPosition = newIndex - 1;
    const listAtNewIndex = boardLists[replacedListId];

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

  fetchIssuesForList: ({ state, commit }, { listId, fetchNext = false }) => {
    commit(types.REQUEST_ISSUES_FOR_LIST, { listId, fetchNext });

    const { endpoints, boardType, filterParams } = state;
    const { fullPath, boardId } = endpoints;

    const variables = {
      fullPath,
      boardId: fullBoardId(boardId),
      id: listId,
      filters: filterParams,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
      first: 20,
      after: fetchNext ? state.pageInfoByListId[listId].endCursor : undefined,
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
        const listPageInfo = formatListsPageInfo(lists);
        commit(types.RECEIVE_ISSUES_FOR_LIST_SUCCESS, { listIssues, listPageInfo, listId });
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

  setActiveIssueLabels: async ({ commit, getters }, input) => {
    const activeIssue = getters.getActiveIssue;
    const { data } = await gqlClient.mutate({
      mutation: issueSetLabels,
      variables: {
        input: {
          iid: String(activeIssue.iid),
          addLabelIds: input.addLabelIds ?? [],
          removeLabelIds: input.removeLabelIds ?? [],
          projectPath: input.projectPath,
        },
      },
    });

    if (data.updateIssue?.errors?.length > 0) {
      throw new Error(data.updateIssue.errors);
    }

    commit(types.UPDATE_ISSUE_BY_ID, {
      issueId: activeIssue.id,
      prop: 'labels',
      value: data.updateIssue.issue.labels.nodes,
    });
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
