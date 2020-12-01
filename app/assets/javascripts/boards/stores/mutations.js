import Vue from 'vue';
import { pull, union } from 'lodash';
import { formatIssue, moveIssueListHelper } from '../boards_util';
import * as mutationTypes from './mutation_types';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const removeIssueFromList = ({ state, listId, issueId }) => {
  Vue.set(state.issuesByListId, listId, pull(state.issuesByListId[listId], issueId));
  const list = state.boardLists[listId];
  Vue.set(state.boardLists, listId, { ...list, issuesSize: list.issuesSize - 1 });
};

export const addIssueToList = ({ state, listId, issueId, moveBeforeId, moveAfterId, atIndex }) => {
  const listIssues = state.issuesByListId[listId];
  let newIndex = atIndex || 0;
  if (moveBeforeId) {
    newIndex = listIssues.indexOf(moveBeforeId) + 1;
  } else if (moveAfterId) {
    newIndex = listIssues.indexOf(moveAfterId);
  }
  listIssues.splice(newIndex, 0, issueId);
  Vue.set(state.issuesByListId, listId, listIssues);
  const list = state.boardLists[listId];
  Vue.set(state.boardLists, listId, { ...list, issuesSize: list.issuesSize + 1 });
};

export default {
  [mutationTypes.SET_INITIAL_BOARD_DATA](state, data) {
    const { boardType, disabled, showPromotion, ...endpoints } = data;
    state.endpoints = endpoints;
    state.boardType = boardType;
    state.disabled = disabled;
    state.showPromotion = showPromotion;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_SUCCESS]: (state, lists) => {
    state.boardLists = lists;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_FAILURE]: state => {
    state.error = s__(
      'Boards|An error occurred while fetching the board lists. Please reload the page.',
    );
  },

  [mutationTypes.SET_ACTIVE_ID](state, { id, sidebarType }) {
    state.activeId = id;
    state.sidebarType = sidebarType;
  },

  [mutationTypes.SET_FILTERS](state, filterParams) {
    state.filterParams = filterParams;
  },

  [mutationTypes.CREATE_LIST_FAILURE]: state => {
    state.error = s__('Boards|An error occurred while creating the list. Please try again.');
  },

  [mutationTypes.RECEIVE_LABELS_FAILURE]: state => {
    state.error = s__('Boards|An error occurred while fetching labels. Please reload the page.');
  },

  [mutationTypes.GENERATE_DEFAULT_LISTS_FAILURE]: state => {
    state.error = s__('Boards|An error occurred while generating lists. Please reload the page.');
  },

  [mutationTypes.REQUEST_ADD_LIST]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_LIST_SUCCESS]: (state, list) => {
    Vue.set(state.boardLists, list.id, list);
  },

  [mutationTypes.RECEIVE_ADD_LIST_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.MOVE_LIST]: (state, { movedList, listAtNewIndex }) => {
    const { boardLists } = state;
    Vue.set(boardLists, movedList.id, movedList);
    Vue.set(boardLists, listAtNewIndex.id, listAtNewIndex);
  },

  [mutationTypes.UPDATE_LIST_FAILURE]: (state, backupList) => {
    state.error = s__('Boards|An error occurred while updating the list. Please try again.');
    Vue.set(state, 'boardLists', backupList);
  },

  [mutationTypes.REMOVE_LIST]: (state, listId) => {
    Vue.delete(state.boardLists, listId);
  },

  [mutationTypes.REMOVE_LIST_FAILURE](state, listsBackup) {
    state.error = s__('Boards|An error occurred while removing the list. Please try again.');
    state.boardLists = listsBackup;
  },

  [mutationTypes.REQUEST_ISSUES_FOR_LIST]: (state, { listId, fetchNext }) => {
    Vue.set(state.listsFlags, listId, { [fetchNext ? 'isLoadingMore' : 'isLoading']: true });
  },

  [mutationTypes.RECEIVE_ISSUES_FOR_LIST_SUCCESS]: (
    state,
    { listIssues, listPageInfo, listId },
  ) => {
    const { listData, issues } = listIssues;
    Vue.set(state, 'issues', { ...state.issues, ...issues });
    Vue.set(
      state.issuesByListId,
      listId,
      union(state.issuesByListId[listId] || [], listData[listId]),
    );
    Vue.set(state.pageInfoByListId, listId, listPageInfo[listId]);
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.RECEIVE_ISSUES_FOR_LIST_FAILURE]: (state, listId) => {
    state.error = s__(
      'Boards|An error occurred while fetching the board issues. Please reload the page.',
    );
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.RESET_ISSUES]: state => {
    Object.keys(state.issuesByListId).forEach(listId => {
      Vue.set(state.issuesByListId, listId, []);
    });
  },

  [mutationTypes.UPDATE_ISSUE_BY_ID]: (state, { issueId, prop, value }) => {
    if (!state.issues[issueId]) {
      /* eslint-disable-next-line @gitlab/require-i18n-strings */
      throw new Error('No issue found.');
    }

    Vue.set(state.issues[issueId], prop, value);
  },

  [mutationTypes.SET_ASSIGNEE_LOADING](state, isLoading) {
    state.isSettingAssignees = isLoading;
  },

  [mutationTypes.REQUEST_ADD_ISSUE]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_ISSUE_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_ADD_ISSUE_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.MOVE_ISSUE]: (
    state,
    { originalIssue, fromListId, toListId, moveBeforeId, moveAfterId },
  ) => {
    const fromList = state.boardLists[fromListId];
    const toList = state.boardLists[toListId];

    const issue = moveIssueListHelper(originalIssue, fromList, toList);
    Vue.set(state.issues, issue.id, issue);

    removeIssueFromList({ state, listId: fromListId, issueId: issue.id });
    addIssueToList({ state, listId: toListId, issueId: issue.id, moveBeforeId, moveAfterId });
  },

  [mutationTypes.MOVE_ISSUE_SUCCESS]: (state, { issue }) => {
    const issueId = getIdFromGraphQLId(issue.id);
    Vue.set(state.issues, issueId, formatIssue({ ...issue, id: issueId }));
  },

  [mutationTypes.MOVE_ISSUE_FAILURE]: (
    state,
    { originalIssue, fromListId, toListId, originalIndex },
  ) => {
    state.error = s__('Boards|An error occurred while moving the issue. Please try again.');
    Vue.set(state.issues, originalIssue.id, originalIssue);
    removeIssueFromList({ state, listId: toListId, issueId: originalIssue.id });
    addIssueToList({
      state,
      listId: fromListId,
      issueId: originalIssue.id,
      atIndex: originalIndex,
    });
  },

  [mutationTypes.REQUEST_UPDATE_ISSUE]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_UPDATE_ISSUE_SUCCESS]: () => {
    notImplemented();
  },

  [mutationTypes.RECEIVE_UPDATE_ISSUE_ERROR]: () => {
    notImplemented();
  },

  [mutationTypes.CREATE_ISSUE_FAILURE]: state => {
    state.error = s__('Boards|An error occurred while creating the issue. Please try again.');
  },

  [mutationTypes.ADD_ISSUE_TO_LIST]: (state, { list, issue, position }) => {
    addIssueToList({
      state,
      listId: list.id,
      issueId: issue.id,
      atIndex: position,
    });
    Vue.set(state.issues, issue.id, issue);
  },

  [mutationTypes.ADD_ISSUE_TO_LIST_FAILURE]: (state, { list, issueId }) => {
    state.error = s__('Boards|An error occurred while creating the issue. Please try again.');
    removeIssueFromList({ state, listId: list.id, issueId });
  },

  [mutationTypes.REMOVE_ISSUE_FROM_LIST]: (state, { list, issue }) => {
    removeIssueFromList({ state, listId: list.id, issueId: issue.id });
    Vue.delete(state.issues, issue.id);
  },

  [mutationTypes.SET_CURRENT_PAGE]: () => {
    notImplemented();
  },

  [mutationTypes.TOGGLE_EMPTY_STATE]: () => {
    notImplemented();
  },
};
