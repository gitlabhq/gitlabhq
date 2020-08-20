import * as types from './mutation_types';
import createDefaultClient from '~/lib/graphql';
import { BoardType } from '~/boards/constants';
import { formatListIssues } from '../boards_util';
import groupListsIssuesQuery from '../queries/group_lists_issues.query.graphql';
import projectListsIssuesQuery from '../queries/project_lists_issues.query.graphql';

const gqlClient = createDefaultClient();

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export default {
  setInitialBoardData: ({ commit }, data) => {
    commit(types.SET_INITIAL_BOARD_DATA, data);
  },

  setActiveId({ commit }, id) {
    commit(types.SET_ACTIVE_ID, id);
  },

  fetchLists: () => {
    notImplemented();
  },

  generateDefaultLists: () => {
    notImplemented();
  },

  createList: () => {
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
      boardId: `gid://gitlab/Board/${boardId}`,
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
