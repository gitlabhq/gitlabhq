import * as Sentry from '@sentry/browser';
import {
  BoardType,
  ListType,
  inactiveId,
  flashAnimationDuration,
  ISSUABLE,
  titleQueries,
  subscriptionQueries,
  deleteListQueries,
  listsQuery,
  updateListQueries,
  issuableTypes,
  FilterFields,
  ListTypeTitles,
} from 'ee_else_ce/boards/constants';
import createBoardListMutation from 'ee_else_ce/boards/graphql/board_list_create.mutation.graphql';
import issueMoveListMutation from 'ee_else_ce/boards/graphql/issue_move_list.mutation.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
// eslint-disable-next-line import/no-deprecated
import { urlParamsToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import {
  formatBoardLists,
  formatListIssues,
  formatListsPageInfo,
  formatIssue,
  formatIssueInput,
  updateListPosition,
  moveItemListHelper,
  getMoveData,
  FiltersInfo,
  filterVariables,
} from '../boards_util';
import boardLabelsQuery from '../graphql/board_labels.query.graphql';
import groupProjectsQuery from '../graphql/group_projects.query.graphql';
import issueCreateMutation from '../graphql/issue_create.mutation.graphql';
import issueSetLabelsMutation from '../graphql/issue_set_labels.mutation.graphql';
import listsIssuesQuery from '../graphql/lists_issues.query.graphql';
import * as types from './mutation_types';

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

  setFilters: ({ commit, state: { issuableType } }, filters) => {
    commit(
      types.SET_FILTERS,
      filterVariables({
        filters,
        issuableType,
        filterInfo: FiltersInfo,
        filterFields: FilterFields,
      }),
    );
  },

  performSearch({ dispatch }) {
    dispatch(
      'setFilters',
      // eslint-disable-next-line import/no-deprecated
      convertObjectPropsToCamelCase(urlParamsToObject(window.location.search)),
    );

    if (gon.features.graphqlBoardLists) {
      dispatch('fetchLists');
      dispatch('resetIssues');
    }
  },

  fetchLists: ({ commit, state, dispatch }) => {
    const { boardType, filterParams, fullPath, fullBoardId, issuableType } = state;

    const variables = {
      fullPath,
      boardId: fullBoardId,
      filters: filterParams,
      ...(issuableType === issuableTypes.issue && {
        isGroup: boardType === BoardType.group,
        isProject: boardType === BoardType.project,
      }),
    };

    return gqlClient
      .query({
        query: listsQuery[issuableType].query,
        variables,
      })
      .then(({ data }) => {
        const { lists, hideBacklogList } = data[boardType]?.board;
        commit(types.RECEIVE_BOARD_LISTS_SUCCESS, formatBoardLists(lists));
        // Backlog list needs to be created if it doesn't exist and it's not hidden
        if (!lists.nodes.find((l) => l.listType === ListType.backlog) && !hideBacklogList) {
          dispatch('createList', { backlog: true });
        }
      })
      .catch(() => commit(types.RECEIVE_BOARD_LISTS_FAILURE));
  },

  highlightList: ({ commit, state }, listId) => {
    if ([ListType.backlog, ListType.closed].includes(state.boardLists[listId].listType)) {
      return;
    }

    commit(types.ADD_LIST_TO_HIGHLIGHTED_LISTS, listId);

    setTimeout(() => {
      commit(types.REMOVE_LIST_FROM_HIGHLIGHTED_LISTS, listId);
    }, flashAnimationDuration);
  },

  createList: ({ dispatch }, { backlog, labelId, milestoneId, assigneeId }) => {
    dispatch('createIssueList', { backlog, labelId, milestoneId, assigneeId });
  },

  createIssueList: (
    { state, commit, dispatch, getters },
    { backlog, labelId, milestoneId, assigneeId, iterationId },
  ) => {
    const { fullBoardId } = state;

    const existingList = getters.getListByLabelId(labelId);

    if (existingList) {
      dispatch('highlightList', existingList.id);
      return;
    }

    gqlClient
      .mutate({
        mutation: createBoardListMutation,
        variables: {
          boardId: fullBoardId,
          backlog,
          labelId,
          milestoneId,
          assigneeId,
          iterationId,
        },
      })
      .then(({ data }) => {
        if (data.boardListCreate?.errors.length) {
          commit(types.CREATE_LIST_FAILURE, data.boardListCreate.errors[0]);
        } else {
          const list = data.boardListCreate?.list;
          dispatch('addList', list);
          dispatch('highlightList', list.id);
        }
      })
      .catch((e) => {
        commit(types.CREATE_LIST_FAILURE);
        throw e;
      });
  },

  addList: ({ commit, dispatch, getters }, list) => {
    commit(types.RECEIVE_ADD_LIST_SUCCESS, updateListPosition(list));
    dispatch('fetchItemsForList', {
      listId: getters.getListByTitle(ListTypeTitles.backlog).id,
    });
  },

  fetchLabels: ({ state, commit, getters }, searchTerm) => {
    const { fullPath, boardType } = state;

    const variables = {
      fullPath,
      searchTerm,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
    };

    commit(types.RECEIVE_LABELS_REQUEST);

    return gqlClient
      .query({
        query: boardLabelsQuery,
        variables,
      })
      .then(({ data }) => {
        let labels = data[boardType]?.labels.nodes;

        if (!getters.shouldUseGraphQL && !getters.isEpicBoard) {
          labels = labels.map((label) => ({
            ...label,
            id: getIdFromGraphQLId(label.id),
          }));
        }

        commit(types.RECEIVE_LABELS_SUCCESS, labels);
        return labels;
      })
      .catch((e) => {
        commit(types.RECEIVE_LABELS_FAILURE);
        throw e;
      });
  },

  moveList: (
    { state, commit, dispatch },
    { listId, replacedListId, newIndex, adjustmentValue },
  ) => {
    if (listId === replacedListId) {
      return;
    }

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

  updateList: (
    { commit, state: { issuableType } },
    { listId, position, collapsed, backupList },
  ) => {
    gqlClient
      .mutate({
        mutation: updateListQueries[issuableType].mutation,
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

  toggleListCollapsed: ({ commit }, { listId, collapsed }) => {
    commit(types.TOGGLE_LIST_COLLAPSED, { listId, collapsed });
  },

  removeList: ({ state: { issuableType, boardLists }, commit, dispatch, getters }, listId) => {
    const listsBackup = { ...boardLists };

    commit(types.REMOVE_LIST, listId);

    return gqlClient
      .mutate({
        mutation: deleteListQueries[issuableType].mutation,
        variables: {
          listId,
        },
      })
      .then(
        ({
          data: {
            destroyBoardList: { errors },
          },
        }) => {
          if (errors.length > 0) {
            commit(types.REMOVE_LIST_FAILURE, listsBackup);
          } else {
            dispatch('fetchItemsForList', {
              listId: getters.getListByTitle(ListTypeTitles.backlog).id,
            });
          }
        },
      )
      .catch(() => {
        commit(types.REMOVE_LIST_FAILURE, listsBackup);
      });
  },

  fetchItemsForList: ({ state, commit }, { listId, fetchNext = false }) => {
    if (!fetchNext) {
      commit(types.RESET_ITEMS_FOR_LIST, listId);
    }
    commit(types.REQUEST_ITEMS_FOR_LIST, { listId, fetchNext });

    const { fullPath, fullBoardId, boardType, filterParams } = state;

    const variables = {
      fullPath,
      boardId: fullBoardId,
      id: listId,
      filters: filterParams,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
      first: 10,
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
        const listItems = formatListIssues(lists);
        const listPageInfo = formatListsPageInfo(lists);
        commit(types.RECEIVE_ITEMS_FOR_LIST_SUCCESS, { listItems, listPageInfo, listId });
      })
      .catch(() => commit(types.RECEIVE_ITEMS_FOR_LIST_FAILURE, listId));
  },

  resetIssues: ({ commit }) => {
    commit(types.RESET_ISSUES);
  },

  moveItem: ({ dispatch }, payload) => {
    dispatch('moveIssue', payload);
  },

  moveIssue: ({ dispatch, state }, params) => {
    const moveData = getMoveData(state, params);

    dispatch('moveIssueCard', moveData);
    dispatch('updateMovedIssue', moveData);
    dispatch('updateIssueOrder', { moveData });
  },

  moveIssueCard: ({ commit }, moveData) => {
    const {
      reordering,
      shouldClone,
      itemNotInToList,
      originalIndex,
      itemId,
      fromListId,
      toListId,
      moveBeforeId,
      moveAfterId,
    } = moveData;

    commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { itemId, listId: fromListId });

    if (reordering) {
      commit(types.ADD_BOARD_ITEM_TO_LIST, {
        itemId,
        listId: toListId,
        moveBeforeId,
        moveAfterId,
      });

      return;
    }

    if (itemNotInToList) {
      commit(types.ADD_BOARD_ITEM_TO_LIST, {
        itemId,
        listId: toListId,
        moveBeforeId,
        moveAfterId,
      });
    }

    if (shouldClone) {
      commit(types.ADD_BOARD_ITEM_TO_LIST, { itemId, listId: fromListId, atIndex: originalIndex });
    }
  },

  updateMovedIssue: (
    { commit, state: { boardItems, boardLists } },
    { itemId, fromListId, toListId },
  ) => {
    const updatedIssue = moveItemListHelper(
      boardItems[itemId],
      boardLists[fromListId],
      boardLists[toListId],
    );

    commit(types.UPDATE_BOARD_ITEM, updatedIssue);
  },

  undoMoveIssueCard: ({ commit }, moveData) => {
    const {
      reordering,
      shouldClone,
      itemNotInToList,
      itemId,
      fromListId,
      toListId,
      originalIssue,
      originalIndex,
    } = moveData;

    commit(types.UPDATE_BOARD_ITEM, originalIssue);

    if (reordering) {
      commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { itemId, listId: fromListId });
      commit(types.ADD_BOARD_ITEM_TO_LIST, { itemId, listId: fromListId, atIndex: originalIndex });
      return;
    }

    if (shouldClone) {
      commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { itemId, listId: fromListId });
    }
    if (itemNotInToList) {
      commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { itemId, listId: toListId });
    }

    commit(types.ADD_BOARD_ITEM_TO_LIST, { itemId, listId: fromListId, atIndex: originalIndex });
  },

  updateIssueOrder: async ({ commit, dispatch, state }, { moveData, mutationVariables = {} }) => {
    try {
      const { itemId, fromListId, toListId, moveBeforeId, moveAfterId } = moveData;
      const {
        fullBoardId,
        boardItems: {
          [itemId]: { iid, referencePath },
        },
      } = state;

      const { data } = await gqlClient.mutate({
        mutation: issueMoveListMutation,
        variables: {
          iid,
          projectPath: referencePath.split(/[#]/)[0],
          boardId: fullBoardId,
          fromListId: getIdFromGraphQLId(fromListId),
          toListId: getIdFromGraphQLId(toListId),
          moveBeforeId,
          moveAfterId,
          // 'mutationVariables' allows EE code to pass in extra parameters.
          ...mutationVariables,
        },
      });

      if (data?.issueMoveList?.errors.length || !data.issueMoveList) {
        throw new Error('issueMoveList empty');
      }

      commit(types.MUTATE_ISSUE_SUCCESS, { issue: data.issueMoveList.issue });
    } catch {
      commit(
        types.SET_ERROR,
        s__('Boards|An error occurred while moving the issue. Please try again.'),
      );
      dispatch('undoMoveIssueCard', moveData);
    }
  },

  setAssignees: ({ commit }, { id, assignees }) => {
    commit('UPDATE_BOARD_ITEM_BY_ID', {
      itemId: id,
      prop: 'assignees',
      value: assignees,
    });
  },

  addListItem: ({ commit }, { list, item, position, inProgress = false }) => {
    commit(types.ADD_BOARD_ITEM_TO_LIST, {
      listId: list.id,
      itemId: item.id,
      atIndex: position,
      inProgress,
    });
    commit(types.UPDATE_BOARD_ITEM, item);
  },

  removeListItem: ({ commit }, { listId, itemId }) => {
    commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { listId, itemId });
    commit(types.REMOVE_BOARD_ITEM, itemId);
  },

  addListNewIssue: (
    { state: { boardConfig, boardType, fullPath }, dispatch, commit },
    { issueInput, list, placeholderId = `tmp-${new Date().getTime()}` },
  ) => {
    const input = formatIssueInput(issueInput, boardConfig);

    if (boardType === BoardType.project) {
      input.projectPath = fullPath;
    }

    const placeholderIssue = formatIssue({ ...issueInput, id: placeholderId, isLoading: true });
    dispatch('addListItem', { list, item: placeholderIssue, position: 0, inProgress: true });

    gqlClient
      .mutate({
        mutation: issueCreateMutation,
        variables: { input },
      })
      .then(({ data }) => {
        if (data.createIssue.errors.length) {
          throw new Error();
        }

        const rawIssue = data.createIssue?.issue;
        const formattedIssue = formatIssue({ ...rawIssue, id: getIdFromGraphQLId(rawIssue.id) });
        dispatch('removeListItem', { listId: list.id, itemId: placeholderId });
        dispatch('addListItem', { list, item: formattedIssue, position: 0 });
      })
      .catch(() => {
        dispatch('removeListItem', { listId: list.id, itemId: placeholderId });
        commit(
          types.SET_ERROR,
          s__('Boards|An error occurred while creating the issue. Please try again.'),
        );
      });
  },

  setActiveBoardItemLabels: ({ dispatch }, params) => {
    dispatch('setActiveIssueLabels', params);
  },

  setActiveIssueLabels: async ({ commit, getters }, input) => {
    const { activeBoardItem } = getters;
    const { data } = await gqlClient.mutate({
      mutation: issueSetLabelsMutation,
      variables: {
        input: {
          iid: String(activeBoardItem.iid),
          addLabelIds: input.addLabelIds ?? [],
          removeLabelIds: input.removeLabelIds ?? [],
          projectPath: input.projectPath,
        },
      },
    });

    if (data.updateIssue?.errors?.length > 0) {
      throw new Error(data.updateIssue.errors);
    }

    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: activeBoardItem.id,
      prop: 'labels',
      value: data.updateIssue.issue.labels.nodes,
    });
  },

  setActiveItemSubscribed: async ({ commit, getters, state }, input) => {
    const { activeBoardItem, isEpicBoard } = getters;
    const { fullPath, issuableType } = state;
    const workspacePath = isEpicBoard
      ? { groupPath: fullPath }
      : { projectPath: input.projectPath };
    const { data } = await gqlClient.mutate({
      mutation: subscriptionQueries[issuableType].mutation,
      variables: {
        input: {
          ...workspacePath,
          iid: String(activeBoardItem.iid),
          subscribedState: input.subscribed,
        },
      },
    });

    if (data.updateIssuableSubscription?.errors?.length > 0) {
      throw new Error(data.updateIssuableSubscription[issuableType].errors);
    }

    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: activeBoardItem.id,
      prop: 'subscribed',
      value: data.updateIssuableSubscription[issuableType].subscribed,
    });
  },

  setActiveItemTitle: async ({ commit, getters, state }, input) => {
    const { activeBoardItem, isEpicBoard } = getters;
    const { fullPath, issuableType } = state;
    const workspacePath = isEpicBoard
      ? { groupPath: fullPath }
      : { projectPath: input.projectPath };
    const { data } = await gqlClient.mutate({
      mutation: titleQueries[issuableType].mutation,
      variables: {
        input: {
          ...workspacePath,
          iid: String(activeBoardItem.iid),
          title: input.title,
        },
      },
    });

    if (data.updateIssuableTitle?.errors?.length > 0) {
      throw new Error(data.updateIssuableTitle.errors);
    }

    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: activeBoardItem.id,
      prop: 'title',
      value: data.updateIssuableTitle[issuableType].title,
    });
  },

  setActiveItemConfidential: ({ commit, getters }, confidential) => {
    const { activeBoardItem } = getters;
    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: activeBoardItem.id,
      prop: 'confidential',
      value: confidential,
    });
  },

  fetchGroupProjects: ({ commit, state }, { search = '', fetchNext = false }) => {
    commit(types.REQUEST_GROUP_PROJECTS, fetchNext);

    const { fullPath } = state;

    const variables = {
      fullPath,
      search: search !== '' ? search : undefined,
      after: fetchNext ? state.groupProjectsFlags.pageInfo.endCursor : undefined,
    };

    return gqlClient
      .query({
        query: groupProjectsQuery,
        variables,
      })
      .then(({ data }) => {
        const { projects } = data.group;
        commit(types.RECEIVE_GROUP_PROJECTS_SUCCESS, {
          projects: projects.nodes,
          pageInfo: projects.pageInfo,
          fetchNext,
        });
      })
      .catch(() => commit(types.RECEIVE_GROUP_PROJECTS_FAILURE));
  },

  setSelectedProject: ({ commit }, project) => {
    commit(types.SET_SELECTED_PROJECT, project);
  },

  toggleBoardItemMultiSelection: ({ commit, state, dispatch, getters }, boardItem) => {
    const { selectedBoardItems } = state;
    const index = selectedBoardItems.indexOf(boardItem);

    // If user already selected an item (activeBoardItem) without using mult-select,
    // include that item in the selection and unset state.ActiveId to hide the sidebar.
    if (getters.activeBoardItem) {
      commit(types.ADD_BOARD_ITEM_TO_SELECTION, getters.activeBoardItem);
      dispatch('unsetActiveId');
    }

    if (index === -1) {
      commit(types.ADD_BOARD_ITEM_TO_SELECTION, boardItem);
    } else {
      commit(types.REMOVE_BOARD_ITEM_FROM_SELECTION, boardItem);
    }
  },

  setAddColumnFormVisibility: ({ commit }, visible) => {
    commit(types.SET_ADD_COLUMN_FORM_VISIBLE, visible);
  },

  resetBoardItemMultiSelection: ({ commit }) => {
    commit(types.RESET_BOARD_ITEM_SELECTION);
  },

  toggleBoardItem: ({ state, dispatch }, { boardItem, sidebarType = ISSUABLE }) => {
    dispatch('resetBoardItemMultiSelection');

    if (boardItem.id === state.activeId) {
      dispatch('unsetActiveId');
    } else {
      dispatch('setActiveId', { id: boardItem.id, sidebarType });
    }
  },

  setError: ({ commit }, { message, error, captureError = true }) => {
    commit(types.SET_ERROR, message);

    if (captureError) {
      Sentry.captureException(error);
    }
  },

  unsetError: ({ commit }) => {
    commit(types.SET_ERROR, undefined);
  },
};
