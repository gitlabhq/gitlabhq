import { pull, union } from 'lodash';
import Vue from 'vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { formatIssue } from '../boards_util';
import { issuableTypes } from '../constants';
import * as mutationTypes from './mutation_types';

const updateListItemsCount = ({ state, listId, value }) => {
  const list = state.boardLists[listId];
  if (state.issuableType === issuableTypes.epic) {
    Vue.set(state.boardLists, listId, { ...list, epicsCount: list.epicsCount + value });
  } else {
    Vue.set(state.boardLists, listId, { ...list, issuesCount: list.issuesCount + value });
  }
};

export const removeItemFromList = ({ state, listId, itemId }) => {
  Vue.set(state.boardItemsByListId, listId, pull(state.boardItemsByListId[listId], itemId));
  updateListItemsCount({ state, listId, value: -1 });
};

export const addItemToList = ({ state, listId, itemId, moveBeforeId, moveAfterId, atIndex }) => {
  const listIssues = state.boardItemsByListId[listId];
  let newIndex = atIndex || 0;
  if (moveBeforeId) {
    newIndex = listIssues.indexOf(moveBeforeId) + 1;
  } else if (moveAfterId) {
    newIndex = listIssues.indexOf(moveAfterId);
  }
  listIssues.splice(newIndex, 0, itemId);
  Vue.set(state.boardItemsByListId, listId, listIssues);
  updateListItemsCount({ state, listId, value: 1 });
};

export default {
  [mutationTypes.SET_INITIAL_BOARD_DATA](state, data) {
    const {
      allowSubEpics,
      boardConfig,
      boardId,
      boardType,
      disabled,
      fullBoardId,
      fullPath,
      issuableType,
    } = data;
    state.allowSubEpics = allowSubEpics;
    state.boardConfig = boardConfig;
    state.boardId = boardId;
    state.boardType = boardType;
    state.disabled = disabled;
    state.fullBoardId = fullBoardId;
    state.fullPath = fullPath;
    state.issuableType = issuableType;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_SUCCESS]: (state, lists) => {
    state.boardLists = lists;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_FAILURE]: (state) => {
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

  [mutationTypes.CREATE_LIST_FAILURE]: (
    state,
    error = s__('Boards|An error occurred while creating the list. Please try again.'),
  ) => {
    state.error = error;
  },

  [mutationTypes.RECEIVE_LABELS_REQUEST]: (state) => {
    state.labelsLoading = true;
  },

  [mutationTypes.RECEIVE_LABELS_SUCCESS]: (state, labels) => {
    state.labels = labels;
    state.labelsLoading = false;
  },

  [mutationTypes.RECEIVE_LABELS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while fetching labels. Please reload the page.');
    state.labelsLoading = false;
  },

  [mutationTypes.GENERATE_DEFAULT_LISTS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while generating lists. Please reload the page.');
  },

  [mutationTypes.RECEIVE_ADD_LIST_SUCCESS]: (state, list) => {
    Vue.set(state.boardLists, list.id, list);
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

  [mutationTypes.TOGGLE_LIST_COLLAPSED]: (state, { listId, collapsed }) => {
    Vue.set(state.boardLists[listId], 'collapsed', collapsed);
  },

  [mutationTypes.REMOVE_LIST]: (state, listId) => {
    Vue.delete(state.boardLists, listId);
  },

  [mutationTypes.REMOVE_LIST_FAILURE](state, listsBackup) {
    state.error = s__('Boards|An error occurred while removing the list. Please try again.');
    state.boardLists = listsBackup;
  },

  [mutationTypes.RESET_ITEMS_FOR_LIST]: (state, listId) => {
    Vue.set(state, 'backupItemsList', state.boardItemsByListId[listId]);
    Vue.set(state.boardItemsByListId, listId, []);
  },

  [mutationTypes.REQUEST_ITEMS_FOR_LIST]: (state, { listId, fetchNext }) => {
    Vue.set(state.listsFlags, listId, { [fetchNext ? 'isLoadingMore' : 'isLoading']: true });
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_SUCCESS]: (state, { listItems, listPageInfo, listId }) => {
    const { listData, boardItems } = listItems;
    Vue.set(state, 'boardItems', { ...state.boardItems, ...boardItems });
    Vue.set(
      state.boardItemsByListId,
      listId,
      union(state.boardItemsByListId[listId] || [], listData[listId]),
    );
    Vue.set(state.pageInfoByListId, listId, listPageInfo[listId]);
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_FAILURE]: (state, listId) => {
    state.error = s__(
      'Boards|An error occurred while fetching the board issues. Please reload the page.',
    );
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
    Vue.set(state.boardItemsByListId, listId, state.backupItemsList);
  },

  [mutationTypes.RESET_ISSUES]: (state) => {
    Object.keys(state.boardItemsByListId).forEach((listId) => {
      Vue.set(state.boardItemsByListId, listId, []);
    });
  },

  [mutationTypes.UPDATE_BOARD_ITEM_BY_ID]: (state, { itemId, prop, value }) => {
    if (!state.boardItems[itemId]) {
      /* eslint-disable-next-line @gitlab/require-i18n-strings */
      throw new Error('No issue found.');
    }

    Vue.set(state.boardItems[itemId], prop, value);
  },

  [mutationTypes.SET_ASSIGNEE_LOADING](state, isLoading) {
    state.isSettingAssignees = isLoading;
  },

  [mutationTypes.MUTATE_ISSUE_SUCCESS]: (state, { issue }) => {
    const issueId = getIdFromGraphQLId(issue.id);
    Vue.set(state.boardItems, issueId, formatIssue({ ...issue, id: issueId }));
  },

  [mutationTypes.ADD_BOARD_ITEM_TO_LIST]: (
    state,
    { itemId, listId, moveBeforeId, moveAfterId, atIndex, inProgress = false },
  ) => {
    Vue.set(state.listsFlags, listId, { ...state.listsFlags, addItemToListInProgress: inProgress });
    addItemToList({ state, listId, itemId, moveBeforeId, moveAfterId, atIndex });
  },

  [mutationTypes.REMOVE_BOARD_ITEM_FROM_LIST]: (state, { itemId, listId }) => {
    removeItemFromList({ state, listId, itemId });
  },

  [mutationTypes.UPDATE_BOARD_ITEM]: (state, item) => {
    Vue.set(state.boardItems, item.id, item);
  },

  [mutationTypes.REMOVE_BOARD_ITEM]: (state, itemId) => {
    Vue.delete(state.boardItems, itemId);
  },

  [mutationTypes.REQUEST_GROUP_PROJECTS]: (state, fetchNext) => {
    Vue.set(state, 'groupProjectsFlags', {
      [fetchNext ? 'isLoadingMore' : 'isLoading']: true,
      pageInfo: state.groupProjectsFlags.pageInfo,
    });
  },

  [mutationTypes.RECEIVE_GROUP_PROJECTS_SUCCESS]: (state, { projects, pageInfo, fetchNext }) => {
    Vue.set(state, 'groupProjects', fetchNext ? [...state.groupProjects, ...projects] : projects);
    Vue.set(state, 'groupProjectsFlags', { isLoading: false, isLoadingMore: false, pageInfo });
  },

  [mutationTypes.RECEIVE_GROUP_PROJECTS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while fetching group projects. Please try again.');
    Vue.set(state, 'groupProjectsFlags', { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.SET_SELECTED_PROJECT]: (state, project) => {
    state.selectedProject = project;
  },

  [mutationTypes.ADD_BOARD_ITEM_TO_SELECTION]: (state, boardItem) => {
    state.selectedBoardItems = [...state.selectedBoardItems, boardItem];
  },

  [mutationTypes.REMOVE_BOARD_ITEM_FROM_SELECTION]: (state, boardItem) => {
    Vue.set(
      state,
      'selectedBoardItems',
      state.selectedBoardItems.filter((obj) => obj !== boardItem),
    );
  },

  [mutationTypes.SET_ADD_COLUMN_FORM_VISIBLE]: (state, visible) => {
    Vue.set(state.addColumnForm, 'visible', visible);
  },

  [mutationTypes.ADD_LIST_TO_HIGHLIGHTED_LISTS]: (state, listId) => {
    state.highlightedLists.push(listId);
  },

  [mutationTypes.REMOVE_LIST_FROM_HIGHLIGHTED_LISTS]: (state, listId) => {
    state.highlightedLists = state.highlightedLists.filter((id) => id !== listId);
  },

  [mutationTypes.RESET_BOARD_ITEM_SELECTION]: (state) => {
    state.selectedBoardItems = [];
  },

  [mutationTypes.SET_ERROR]: (state, error) => {
    state.error = error;
  },
};
