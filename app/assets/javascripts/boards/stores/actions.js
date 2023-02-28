import * as Sentry from '@sentry/browser';
import { sortBy } from 'lodash';
import {
  ListType,
  inactiveId,
  flashAnimationDuration,
  ISSUABLE,
  titleQueries,
  subscriptionQueries,
  deleteListQueries,
  listsQuery,
  updateListQueries,
  FilterFields,
  ListTypeTitles,
  DraggableItemTypes,
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
} from 'ee_else_ce/boards/constants';
import {
  formatIssueInput,
  formatBoardLists,
  formatListIssues,
  formatListsPageInfo,
  formatIssue,
  updateListPosition,
  moveItemListHelper,
  getMoveData,
  FiltersInfo,
  filterVariables,
} from 'ee_else_ce/boards/boards_util';
import createBoardListMutation from 'ee_else_ce/boards/graphql/board_list_create.mutation.graphql';
import issueMoveListMutation from 'ee_else_ce/boards/graphql/issue_move_list.mutation.graphql';
import totalCountAndWeightQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { defaultClient as gqlClient } from '~/graphql_shared/issuable_client';
import { TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import eventHub from '../eventhub';
import projectBoardQuery from '../graphql/project_board.query.graphql';
import groupBoardQuery from '../graphql/group_board.query.graphql';
import boardLabelsQuery from '../graphql/board_labels.query.graphql';
import groupBoardMilestonesQuery from '../graphql/group_board_milestones.query.graphql';
import groupProjectsQuery from '../graphql/group_projects.query.graphql';
import issueCreateMutation from '../graphql/issue_create.mutation.graphql';
import listsIssuesQuery from '../graphql/lists_issues.query.graphql';
import projectBoardMilestonesQuery from '../graphql/project_board_milestones.query.graphql';

import * as types from './mutation_types';

export default {
  fetchBoard: ({ commit, dispatch }, { fullPath, fullBoardId, boardType }) => {
    commit(types.REQUEST_CURRENT_BOARD);

    const variables = {
      fullPath,
      boardId: fullBoardId,
    };

    return gqlClient
      .query({
        query: boardType === WORKSPACE_GROUP ? groupBoardQuery : projectBoardQuery,
        variables,
      })
      .then(({ data }) => {
        if (data.workspace?.errors) {
          commit(types.RECEIVE_BOARD_FAILURE);
        } else {
          const board = data.workspace?.board;
          dispatch('setBoard', board);
        }
      })
      .catch(() => commit(types.RECEIVE_BOARD_FAILURE));
  },

  setInitialBoardData: ({ commit }, data) => {
    commit(types.SET_INITIAL_BOARD_DATA, data);
  },

  setBoardConfig: ({ commit }, board) => {
    const config = {
      milestoneId: board.milestone?.id || null,
      milestoneTitle: board.milestone?.title || null,
      iterationId: board.iteration?.id || null,
      iterationTitle: board.iteration?.title || null,
      iterationCadenceId: board.iterationCadence?.id || null,
      assigneeId: board.assignee?.id || null,
      assigneeUsername: board.assignee?.username || null,
      labels: board.labels?.nodes || [],
      labelIds: board.labels?.nodes?.map((label) => label.id) || [],
      weight: board.weight,
    };
    commit(types.SET_BOARD_CONFIG, config);
  },

  setBoard: async ({ commit, dispatch }, board) => {
    commit(types.RECEIVE_BOARD_SUCCESS, board);
    await dispatch('setBoardConfig', board);
    dispatch('performSearch', { resetLists: true });
    eventHub.$emit('updateTokens');
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

  performSearch({ dispatch }, { resetLists = false } = {}) {
    dispatch(
      'setFilters',
      convertObjectPropsToCamelCase(queryToObject(window.location.search, { gatherArrays: true })),
    );
    dispatch('fetchLists', { resetLists });
    dispatch('resetIssues');
  },

  fetchLists: ({ commit, state, dispatch }, { resetLists = false } = {}) => {
    const { boardType, filterParams, fullPath, fullBoardId, issuableType } = state;

    const variables = {
      fullPath,
      boardId: fullBoardId,
      filters: filterParams,
      ...(issuableType === TYPE_ISSUE && {
        isGroup: boardType === WORKSPACE_GROUP,
        isProject: boardType === WORKSPACE_PROJECT,
      }),
    };

    return gqlClient
      .query({
        query: listsQuery[issuableType].query,
        variables,
        ...(resetLists ? { fetchPolicy: fetchPolicies.NO_CACHE } : {}),
        context: {
          isSingleRequest: true,
        },
      })
      .then(({ data }) => {
        const { lists, hideBacklogList } = data[boardType].board;
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
      listId: getters.getListByTitle(ListTypeTitles.backlog)?.id,
    });
  },

  fetchLabels: ({ state, commit }, searchTerm) => {
    const { fullPath, boardType } = state;

    const variables = {
      fullPath,
      searchTerm,
      isGroup: boardType === WORKSPACE_GROUP,
      isProject: boardType === WORKSPACE_PROJECT,
    };

    commit(types.RECEIVE_LABELS_REQUEST);

    return gqlClient
      .query({
        query: boardLabelsQuery,
        variables,
      })
      .then(({ data }) => {
        const labels = data[boardType]?.labels.nodes;

        commit(types.RECEIVE_LABELS_SUCCESS, labels);
        return labels;
      })
      .catch((e) => {
        commit(types.RECEIVE_LABELS_FAILURE);
        throw e;
      });
  },

  fetchMilestones({ state, commit }, searchTerm) {
    commit(types.RECEIVE_MILESTONES_REQUEST);

    const { fullPath, boardType } = state;

    const variables = {
      fullPath,
      searchTerm,
    };

    let query;
    if (boardType === WORKSPACE_PROJECT) {
      query = projectBoardMilestonesQuery;
    }
    if (boardType === WORKSPACE_GROUP) {
      query = groupBoardMilestonesQuery;
    }

    if (!query) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Unknown board type');
    }

    return gqlClient
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        const errors = data.workspace?.errors;
        const milestones = data.workspace?.milestones.nodes;

        if (errors?.[0]) {
          throw new Error(errors[0]);
        }

        commit(types.RECEIVE_MILESTONES_SUCCESS, milestones);

        return milestones;
      })
      .catch((e) => {
        commit(types.RECEIVE_MILESTONES_FAILURE);
        throw e;
      });
  },

  moveList: (
    { state: { boardLists }, commit, dispatch },
    {
      item: {
        dataset: { listId: movedListId, draggableItemType },
      },
      newIndex,
      to: { children },
    },
  ) => {
    if (draggableItemType !== DraggableItemTypes.list) {
      return;
    }

    const displacedListId = children[newIndex].dataset.listId;
    if (movedListId === displacedListId) {
      return;
    }

    const listIds = sortBy(
      Object.keys(boardLists).filter(
        (listId) =>
          listId !== movedListId &&
          boardLists[listId].listType !== ListType.backlog &&
          boardLists[listId].listType !== ListType.closed,
      ),
      (i) => boardLists[i].position,
    );

    const targetPosition = boardLists[displacedListId].position;
    // When the dragged list moves left, displaced list should shift right.
    const shiftOffset = Number(boardLists[movedListId].position < targetPosition);
    const displacedListIndex = listIds.findIndex((listId) => listId === displacedListId);

    commit(
      types.MOVE_LISTS,
      listIds
        .slice(0, displacedListIndex + shiftOffset)
        .concat([movedListId], listIds.slice(displacedListIndex + shiftOffset))
        .map((listId, index) => ({ listId, position: index })),
    );
    dispatch('updateList', { listId: movedListId, position: targetPosition });
  },

  updateList: (
    { state: { issuableType, boardItemsByListId = {} }, dispatch },
    { listId, position, collapsed },
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
          throw new Error();
        }

        // Only fetch when board items havent been fetched on a collapsed list
        if (!boardItemsByListId[listId]) {
          dispatch('fetchItemsForList', { listId });
        }
      })
      .catch(() => {
        dispatch('handleUpdateListFailure');
      });
  },

  handleUpdateListFailure: ({ dispatch, commit }) => {
    dispatch('fetchLists');

    commit(
      types.SET_ERROR,
      s__('Boards|An error occurred while updating the board list. Please try again.'),
    );
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
              listId: getters.getListByTitle(ListTypeTitles.backlog)?.id,
            });
          }
        },
      )
      .catch(() => {
        commit(types.REMOVE_LIST_FAILURE, listsBackup);
      });
  },

  fetchItemsForList: ({ state, commit }, { listId, fetchNext = false }) => {
    if (!listId) return null;

    commit(types.REQUEST_ITEMS_FOR_LIST, { listId, fetchNext });

    const { fullPath, fullBoardId, boardType, filterParams } = state;
    const variables = {
      fullPath,
      boardId: fullBoardId,
      id: listId,
      filters: filterParams,
      isGroup: boardType === WORKSPACE_GROUP,
      isProject: boardType === WORKSPACE_PROJECT,
      first: DEFAULT_BOARD_LIST_ITEMS_SIZE,
      after: fetchNext ? state.pageInfoByListId[listId].endCursor : undefined,
    };

    return gqlClient
      .query({
        query: listsIssuesQuery,
        context: {
          isSingleRequest: true,
        },
        variables,
        ...(!fetchNext ? { fetchPolicy: fetchPolicies.NO_CACHE } : {}),
      })
      .then(({ data }) => {
        const { lists } = data[boardType].board;
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
      positionInList,
      allItemsLoadedInList,
    } = moveData;

    commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { itemId, listId: fromListId });

    if (reordering && !allItemsLoadedInList && positionInList === -1) {
      return;
    }

    if (reordering) {
      commit(types.ADD_BOARD_ITEM_TO_LIST, {
        itemId,
        listId: toListId,
        moveBeforeId,
        moveAfterId,
        positionInList,
        atIndex: originalIndex,
        allItemsLoadedInList,
      });

      return;
    }

    if (itemNotInToList) {
      commit(types.ADD_BOARD_ITEM_TO_LIST, {
        itemId,
        listId: toListId,
        moveBeforeId,
        moveAfterId,
        positionInList,
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
      const {
        itemId,
        fromListId,
        toListId,
        moveBeforeId,
        moveAfterId,
        itemNotInToList,
        positionInList,
      } = moveData;
      const {
        fullBoardId,
        filterParams,
        boardItems: {
          [itemId]: { iid, referencePath },
        },
      } = state;

      commit(types.MUTATE_ISSUE_IN_PROGRESS, true);

      const { data } = await gqlClient.mutate({
        mutation: issueMoveListMutation,
        variables: {
          iid,
          projectPath: referencePath.split(/[#]/)[0],
          boardId: fullBoardId,
          fromListId: getIdFromGraphQLId(fromListId),
          toListId: getIdFromGraphQLId(toListId),
          moveBeforeId: moveBeforeId ? getIdFromGraphQLId(moveBeforeId) : undefined,
          moveAfterId: moveAfterId ? getIdFromGraphQLId(moveAfterId) : undefined,
          positionInList,
          // 'mutationVariables' allows EE code to pass in extra parameters.
          ...mutationVariables,
        },
        update(
          cache,
          {
            data: {
              issueMoveList: {
                issue: { weight },
              },
            },
          },
        ) {
          if (fromListId === toListId) return;

          const updateFromList = () => {
            const fromList = cache.readQuery({
              query: totalCountAndWeightQuery,
              variables: { id: fromListId, filters: filterParams },
            });

            const updatedFromList = {
              boardList: {
                __typename: 'BoardList',
                id: fromList.boardList.id,
                issuesCount: fromList.boardList.issuesCount - 1,
                totalWeight: fromList.boardList.totalWeight - Number(weight),
              },
            };

            cache.writeQuery({
              query: totalCountAndWeightQuery,
              variables: { id: fromListId, filters: filterParams },
              data: updatedFromList,
            });
          };

          const updateToList = () => {
            if (!itemNotInToList) return;

            const toList = cache.readQuery({
              query: totalCountAndWeightQuery,
              variables: { id: toListId, filters: filterParams },
            });

            const updatedToList = {
              boardList: {
                __typename: 'BoardList',
                id: toList.boardList.id,
                issuesCount: toList.boardList.issuesCount + 1,
                totalWeight: toList.boardList.totalWeight + Number(weight),
              },
            };

            cache.writeQuery({
              query: totalCountAndWeightQuery,
              variables: { id: toListId, filters: filterParams },
              data: updatedToList,
            });
          };

          updateFromList();
          updateToList();
        },
      });

      if (data?.issueMoveList?.errors.length || !data.issueMoveList) {
        throw new Error('issueMoveList empty');
      }

      commit(types.MUTATE_ISSUE_SUCCESS, { issue: data.issueMoveList.issue });
      commit(types.MUTATE_ISSUE_IN_PROGRESS, false);
    } catch {
      commit(types.MUTATE_ISSUE_IN_PROGRESS, false);
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

  addListItem: ({ commit, dispatch }, { list, item, position, inProgress = false }) => {
    commit(types.ADD_BOARD_ITEM_TO_LIST, {
      listId: list.id,
      itemId: item.id,
      atIndex: position,
      inProgress,
    });
    commit(types.UPDATE_BOARD_ITEM, item);
    if (!inProgress) {
      dispatch('setActiveId', { id: item.id, sidebarType: ISSUABLE });
    }
  },

  removeListItem: ({ commit }, { listId, itemId }) => {
    commit(types.REMOVE_BOARD_ITEM_FROM_LIST, { listId, itemId });
    commit(types.REMOVE_BOARD_ITEM, itemId);
  },

  addListNewIssue: (
    { state: { boardConfig, boardType, fullPath, filterParams }, dispatch, commit },
    { issueInput, list, placeholderId = `tmp-${new Date().getTime()}` },
  ) => {
    const input = formatIssueInput(issueInput, boardConfig);

    if (boardType === WORKSPACE_PROJECT) {
      input.projectPath = fullPath;
    }

    const placeholderIssue = formatIssue({ ...issueInput, id: placeholderId, isLoading: true });
    dispatch('addListItem', { list, item: placeholderIssue, position: 0, inProgress: true });

    gqlClient
      .mutate({
        mutation: issueCreateMutation,
        variables: { input },
        update(cache) {
          const fromList = cache.readQuery({
            query: totalCountAndWeightQuery,
            variables: { id: list.id, filters: filterParams },
          });

          const updatedList = {
            boardList: {
              __typename: 'BoardList',
              id: fromList.boardList.id,
              issuesCount: fromList.boardList.issuesCount + 1,
              totalWeight: fromList.boardList.totalWeight,
            },
          };

          cache.writeQuery({
            query: totalCountAndWeightQuery,
            variables: { id: list.id, filters: filterParams },
            data: updatedList,
          });
        },
      })
      .then(({ data }) => {
        if (data.createIssue.errors.length) {
          throw new Error();
        }

        const rawIssue = data.createIssue?.issue;
        const formattedIssue = formatIssue(rawIssue);
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

    let labels = input?.labels || [];
    if (input.removeLabelIds) {
      labels = activeBoardItem.labels.filter(
        (label) => input.removeLabelIds[0] !== getIdFromGraphQLId(label.id),
      );
    }
    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: input.id || activeBoardItem.id,
      prop: 'labels',
      value: labels,
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

  // EE action needs CE empty equivalent
  setActiveItemWeight: () => {},
  setActiveItemHealthStatus: () => {},
};
