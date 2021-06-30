import * as Sentry from '@sentry/browser';
import {
  inactiveId,
  ISSUABLE,
  ListType,
  issuableTypes,
  BoardType,
  listsQuery,
} from 'ee_else_ce/boards/constants';
import issueMoveListMutation from 'ee_else_ce/boards/graphql/issue_move_list.mutation.graphql';
import testAction from 'helpers/vuex_action_helper';
import {
  formatListIssues,
  formatBoardLists,
  formatIssueInput,
  formatIssue,
  getMoveData,
  updateListPosition,
} from '~/boards/boards_util';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import actions, { gqlClient } from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import {
  mockLists,
  mockListsById,
  mockIssue,
  mockIssue2,
  rawIssue,
  mockIssues,
  labels,
  mockActiveIssue,
  mockGroupProjects,
  mockMoveIssueParams,
  mockMoveState,
  mockMoveData,
  mockList,
} from '../mock_data';

jest.mock('~/flash');

// We need this helper to make sure projectPath is including
// subgroups when the movIssue action is called.
const getProjectPath = (path) => path.split('#')[0];

beforeEach(() => {
  window.gon = { features: {} };
});

describe('setInitialBoardData', () => {
  it('sets data object', () => {
    const mockData = {
      foo: 'bar',
      bar: 'baz',
    };

    return testAction(
      actions.setInitialBoardData,
      mockData,
      {},
      [{ type: types.SET_INITIAL_BOARD_DATA, payload: mockData }],
      [],
    );
  });
});

describe('setFilters', () => {
  it.each([
    [
      'with correct filters as payload',
      {
        filters: { labelName: 'label', foobar: 'not-a-filter', search: 'quick brown fox' },
        filterVariables: { labelName: 'label', search: 'quick brown fox', not: {} },
      },
    ],
    [
      "and use 'assigneeWildcardId' as filter variable for 'assigneId' param",
      {
        filters: { assigneeId: 'None' },
        filterVariables: { assigneeWildcardId: 'NONE', not: {} },
      },
    ],
  ])('should commit mutation SET_FILTERS %s', (_, { filters, filterVariables }) => {
    const state = {
      filters: {},
      issuableType: issuableTypes.issue,
    };

    testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: filterVariables }],
      [],
    );
  });
});

describe('performSearch', () => {
  it('should dispatch setFilters action', (done) => {
    testAction(actions.performSearch, {}, {}, [], [{ type: 'setFilters', payload: {} }], done);
  });

  it('should dispatch setFilters, fetchLists and resetIssues action when graphqlBoardLists FF is on', (done) => {
    window.gon = { features: { graphqlBoardLists: true } };
    testAction(
      actions.performSearch,
      {},
      {},
      [],
      [{ type: 'setFilters', payload: {} }, { type: 'fetchLists' }, { type: 'resetIssues' }],
      done,
    );
  });
});

describe('setActiveId', () => {
  it('should commit mutation SET_ACTIVE_ID', (done) => {
    const state = {
      activeId: inactiveId,
    };

    testAction(
      actions.setActiveId,
      { id: 1, sidebarType: 'something' },
      state,
      [{ type: types.SET_ACTIVE_ID, payload: { id: 1, sidebarType: 'something' } }],
      [],
      done,
    );
  });
});

describe('fetchLists', () => {
  let state = {
    fullPath: 'gitlab-org',
    fullBoardId: 'gid://gitlab/Board/1',
    filterParams: {},
    boardType: 'group',
    issuableType: 'issue',
  };

  let queryResponse = {
    data: {
      group: {
        board: {
          hideBacklogList: true,
          lists: {
            nodes: [mockLists[1]],
          },
        },
      },
    },
  };

  const formattedLists = formatBoardLists(queryResponse.data.group.board.lists);

  it('should commit mutations RECEIVE_BOARD_LISTS_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_SUCCESS,
          payload: formattedLists,
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations RECEIVE_BOARD_LISTS_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    testAction(
      actions.fetchLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_FAILURE,
        },
      ],
      [],
      done,
    );
  });

  it('dispatch createList action when backlog list does not exist and is not hidden', (done) => {
    queryResponse = {
      data: {
        group: {
          board: {
            hideBacklogList: false,
            lists: {
              nodes: [mockLists[1]],
            },
          },
        },
      },
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_SUCCESS,
          payload: formattedLists,
        },
      ],
      [{ type: 'createList', payload: { backlog: true } }],
      done,
    );
  });

  it.each`
    issuableType           | boardType            | fullBoardId               | isGroup  | isProject
    ${issuableTypes.issue} | ${BoardType.group}   | ${'gid://gitlab/Board/1'} | ${true}  | ${false}
    ${issuableTypes.issue} | ${BoardType.project} | ${'gid://gitlab/Board/1'} | ${false} | ${true}
  `(
    'calls $issuableType query with correct variables',
    async ({ issuableType, boardType, fullBoardId, isGroup, isProject }) => {
      const commit = jest.fn();
      const dispatch = jest.fn();

      state = {
        fullPath: 'gitlab-org',
        fullBoardId,
        filterParams: {},
        boardType,
        issuableType,
      };

      const variables = {
        query: listsQuery[issuableType].query,
        variables: {
          fullPath: 'gitlab-org',
          boardId: fullBoardId,
          filters: {},
          isGroup,
          isProject,
        },
      };

      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchLists({ commit, state, dispatch });

      expect(gqlClient.query).toHaveBeenCalledWith(variables);
    },
  );
});

describe('createList', () => {
  it('should dispatch createIssueList action', () => {
    testAction({
      action: actions.createList,
      payload: { backlog: true },
      expectedActions: [{ type: 'createIssueList', payload: { backlog: true } }],
    });
  });
});

describe('createIssueList', () => {
  let commit;
  let dispatch;
  let getters;
  let state;

  beforeEach(() => {
    state = {
      fullPath: 'gitlab-org',
      fullBoardId: 'gid://gitlab/Board/1',
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
    };
    commit = jest.fn();
    dispatch = jest.fn();
    getters = {
      getListByLabelId: jest.fn(),
    };
  });

  it('should dispatch addList action when creating backlog list', async () => {
    const backlogList = {
      id: 'gid://gitlab/List/1',
      listType: 'backlog',
      title: 'Open',
      position: 0,
    };

    jest.spyOn(gqlClient, 'mutate').mockReturnValue(
      Promise.resolve({
        data: {
          boardListCreate: {
            list: backlogList,
            errors: [],
          },
        },
      }),
    );

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('addList', backlogList);
  });

  it('dispatches highlightList after addList has succeeded', async () => {
    const list = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Open',
      labelId: '4',
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        boardListCreate: {
          list,
          errors: [],
        },
      },
    });

    await actions.createIssueList({ getters, state, commit, dispatch }, { labelId: '4' });

    expect(dispatch).toHaveBeenCalledWith('addList', list);
    expect(dispatch).toHaveBeenCalledWith('highlightList', list.id);
  });

  it('should commit CREATE_LIST_FAILURE mutation when API returns an error', async () => {
    jest.spyOn(gqlClient, 'mutate').mockReturnValue(
      Promise.resolve({
        data: {
          boardListCreate: {
            list: {},
            errors: ['foo'],
          },
        },
      }),
    );

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(commit).toHaveBeenCalledWith(types.CREATE_LIST_FAILURE, 'foo');
  });

  it('highlights list and does not re-query if it already exists', async () => {
    const existingList = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Some label',
      position: 1,
    };

    getters = {
      getListByLabelId: jest.fn().mockReturnValue(existingList),
    };

    await actions.createIssueList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('highlightList', existingList.id);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(commit).not.toHaveBeenCalled();
  });
});

describe('addList', () => {
  const getters = {
    getListByTitle: jest.fn().mockReturnValue(mockList),
  };

  it('should commit RECEIVE_ADD_LIST_SUCCESS mutation and  dispatch fetchItemsForList action', () => {
    testAction({
      action: actions.addList,
      payload: mockLists[1],
      state: { ...getters },
      expectedMutations: [
        { type: types.RECEIVE_ADD_LIST_SUCCESS, payload: updateListPosition(mockLists[1]) },
      ],
      expectedActions: [{ type: 'fetchItemsForList', payload: { listId: mockList.id } }],
    });
  });
});

describe('fetchLabels', () => {
  it('should commit mutation RECEIVE_LABELS_SUCCESS on success', async () => {
    const queryResponse = {
      data: {
        group: {
          labels: {
            nodes: labels,
          },
        },
      },
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const commit = jest.fn();
    const getters = {
      shouldUseGraphQL: () => true,
    };
    const state = { boardType: 'group' };

    await actions.fetchLabels({ getters, state, commit });

    expect(commit).toHaveBeenCalledWith(types.RECEIVE_LABELS_SUCCESS, labels);
  });
});

describe('moveList', () => {
  it('should commit MOVE_LIST mutation and dispatch updateList action', (done) => {
    const initialBoardListsState = {
      'gid://gitlab/List/1': mockLists[0],
      'gid://gitlab/List/2': mockLists[1],
    };

    const state = {
      fullPath: 'gitlab-org',
      fullBoardId: 'gid://gitlab/Board/1',
      boardType: 'group',
      disabled: false,
      boardLists: initialBoardListsState,
    };

    testAction(
      actions.moveList,
      {
        listId: 'gid://gitlab/List/1',
        replacedListId: 'gid://gitlab/List/2',
        newIndex: 1,
        adjustmentValue: 1,
      },
      state,
      [
        {
          type: types.MOVE_LIST,
          payload: { movedList: mockLists[0], listAtNewIndex: mockLists[1] },
        },
      ],
      [
        {
          type: 'updateList',
          payload: {
            listId: 'gid://gitlab/List/1',
            position: 0,
            backupList: initialBoardListsState,
          },
        },
      ],
      done,
    );
  });

  it('should not commit MOVE_LIST or dispatch updateList if listId and replacedListId are the same', () => {
    const initialBoardListsState = {
      'gid://gitlab/List/1': mockLists[0],
      'gid://gitlab/List/2': mockLists[1],
    };

    const state = {
      fullPath: 'gitlab-org',
      fullBoardId: 'gid://gitlab/Board/1',
      boardType: 'group',
      disabled: false,
      boardLists: initialBoardListsState,
    };

    testAction(
      actions.moveList,
      {
        listId: 'gid://gitlab/List/1',
        replacedListId: 'gid://gitlab/List/1',
        newIndex: 1,
        adjustmentValue: 1,
      },
      state,
      [],
      [],
    );
  });
});

describe('updateList', () => {
  it('should commit UPDATE_LIST_FAILURE mutation when API returns an error', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateBoardList: {
          list: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    const state = {
      fullPath: 'gitlab-org',
      fullBoardId: 'gid://gitlab/Board/1',
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
      issuableType: issuableTypes.issue,
    };

    testAction(
      actions.updateList,
      { listId: 'gid://gitlab/List/1', position: 1 },
      state,
      [{ type: types.UPDATE_LIST_FAILURE }],
      [],
      done,
    );
  });
});

describe('toggleListCollapsed', () => {
  it('should commit TOGGLE_LIST_COLLAPSED mutation', async () => {
    const payload = { listId: 'gid://gitlab/List/1', collapsed: true };
    await testAction({
      action: actions.toggleListCollapsed,
      payload,
      expectedMutations: [
        {
          type: types.TOGGLE_LIST_COLLAPSED,
          payload,
        },
      ],
    });
  });
});

describe('removeList', () => {
  let state;
  let getters;
  const list = mockLists[1];
  const listId = list.id;
  const mutationVariables = {
    mutation: destroyBoardListMutation,
    variables: {
      listId,
    },
  };

  beforeEach(() => {
    state = {
      boardLists: mockListsById,
      issuableType: issuableTypes.issue,
    };
    getters = {
      getListByTitle: jest.fn().mockReturnValue(mockList),
    };
  });

  afterEach(() => {
    state = null;
  });

  it('optimistically deletes the list', () => {
    const commit = jest.fn();

    actions.removeList({ commit, state, getters, dispatch: () => {} }, listId);

    expect(commit.mock.calls).toEqual([[types.REMOVE_LIST, listId]]);
  });

  it('keeps the updated list if remove succeeds', async () => {
    const commit = jest.fn();
    const dispatch = jest.fn();

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        destroyBoardList: {
          errors: [],
        },
      },
    });

    await actions.removeList({ commit, state, getters, dispatch }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([[types.REMOVE_LIST, listId]]);
    expect(dispatch.mock.calls).toEqual([['fetchItemsForList', { listId: mockList.id }]]);
  });

  it('restores the list if update fails', async () => {
    const commit = jest.fn();
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(Promise.reject());

    await actions.removeList({ commit, state, getters, dispatch: () => {} }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([
      [types.REMOVE_LIST, listId],
      [types.REMOVE_LIST_FAILURE, mockListsById],
    ]);
  });

  it('restores the list if update response has errors', async () => {
    const commit = jest.fn();
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        destroyBoardList: {
          errors: ['update failed, ID invalid'],
        },
      },
    });

    await actions.removeList({ commit, state, getters, dispatch: () => {} }, listId);

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
    expect(commit.mock.calls).toEqual([
      [types.REMOVE_LIST, listId],
      [types.REMOVE_LIST_FAILURE, mockListsById],
    ]);
  });
});

describe('fetchItemsForList', () => {
  const listId = mockLists[0].id;

  const state = {
    fullPath: 'gitlab-org',
    fullBoardId: 'gid://gitlab/Board/1',
    filterParams: {},
    boardType: 'group',
  };

  const mockIssuesNodes = mockIssues.map((issue) => ({ node: issue }));

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          lists: {
            nodes: [
              {
                id: listId,
                issues: {
                  edges: mockIssuesNodes,
                  pageInfo,
                },
              },
            ],
          },
        },
      },
    },
  };

  const formattedIssues = formatListIssues(queryResponse.data.group.board.lists);

  const listPageInfo = {
    [listId]: pageInfo,
  };

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
        {
          type: types.RESET_ITEMS_FOR_LIST,
          payload: listId,
        },
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        {
          type: types.RECEIVE_ITEMS_FOR_LIST_SUCCESS,
          payload: { listItems: formattedIssues, listPageInfo, listId },
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
        {
          type: types.RESET_ITEMS_FOR_LIST,
          payload: listId,
        },
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        { type: types.RECEIVE_ITEMS_FOR_LIST_FAILURE, payload: listId },
      ],
      [],
      done,
    );
  });
});

describe('resetIssues', () => {
  it('commits RESET_ISSUES mutation', () => {
    return testAction(actions.resetIssues, {}, {}, [{ type: types.RESET_ISSUES }], []);
  });
});

describe('moveItem', () => {
  it('should dispatch moveIssue action with payload', () => {
    const payload = { mock: 'payload' };

    testAction({
      action: actions.moveItem,
      payload,
      expectedActions: [{ type: 'moveIssue', payload }],
    });
  });
});

describe('moveIssue', () => {
  it('should dispatch a correct set of actions', () => {
    testAction({
      action: actions.moveIssue,
      payload: mockMoveIssueParams,
      state: mockMoveState,
      expectedActions: [
        { type: 'moveIssueCard', payload: mockMoveData },
        { type: 'updateMovedIssue', payload: mockMoveData },
        { type: 'updateIssueOrder', payload: { moveData: mockMoveData } },
      ],
    });
  });
});

describe('moveIssueCard and undoMoveIssueCard', () => {
  describe('card should move without clonning', () => {
    let state;
    let params;
    let moveMutations;
    let undoMutations;

    describe('when re-ordering card', () => {
      beforeEach(
        ({
          itemId = 123,
          fromListId = 'gid://gitlab/List/1',
          toListId = 'gid://gitlab/List/1',
          originalIssue = { foo: 'bar' },
          originalIndex = 0,
          moveBeforeId = undefined,
          moveAfterId = undefined,
        } = {}) => {
          state = {
            boardLists: {
              [toListId]: { listType: ListType.backlog },
              [fromListId]: { listType: ListType.backlog },
            },
            boardItems: { [itemId]: originalIssue },
            boardItemsByListId: { [fromListId]: [123] },
          };
          params = { itemId, fromListId, toListId, moveBeforeId, moveAfterId };
          moveMutations = [
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: toListId, moveBeforeId, moveAfterId },
            },
          ];
          undoMutations = [
            { type: types.UPDATE_BOARD_ITEM, payload: originalIssue },
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: fromListId, atIndex: originalIndex },
            },
          ];
        },
      );

      it('moveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.moveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: moveMutations,
        });
      });

      it('undoMoveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.undoMoveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: undoMutations,
        });
      });
    });

    describe.each([
      [
        'issue moves out of backlog',
        {
          fromListType: ListType.backlog,
          toListType: ListType.label,
        },
      ],
      [
        'issue card moves to closed',
        {
          fromListType: ListType.label,
          toListType: ListType.closed,
        },
      ],
      [
        'issue card moves to non-closed, non-backlog list of the same type',
        {
          fromListType: ListType.label,
          toListType: ListType.label,
        },
      ],
    ])('when %s', (_, { toListType, fromListType }) => {
      beforeEach(
        ({
          itemId = 123,
          fromListId = 'gid://gitlab/List/1',
          toListId = 'gid://gitlab/List/2',
          originalIssue = { foo: 'bar' },
          originalIndex = 0,
          moveBeforeId = undefined,
          moveAfterId = undefined,
        } = {}) => {
          state = {
            boardLists: {
              [fromListId]: { listType: fromListType },
              [toListId]: { listType: toListType },
            },
            boardItems: { [itemId]: originalIssue },
            boardItemsByListId: { [fromListId]: [123], [toListId]: [] },
          };
          params = { itemId, fromListId, toListId, moveBeforeId, moveAfterId };
          moveMutations = [
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: toListId, moveBeforeId, moveAfterId },
            },
          ];
          undoMutations = [
            { type: types.UPDATE_BOARD_ITEM, payload: originalIssue },
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: toListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: fromListId, atIndex: originalIndex },
            },
          ];
        },
      );

      it('moveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.moveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: moveMutations,
        });
      });

      it('undoMoveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.undoMoveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: undoMutations,
        });
      });
    });
  });

  describe('card should clone on move', () => {
    let state;
    let params;
    let moveMutations;
    let undoMutations;

    describe.each([
      [
        'issue card moves to non-closed, non-backlog list of a different type',
        {
          fromListType: ListType.label,
          toListType: ListType.assignee,
        },
      ],
    ])('when %s', (_, { toListType, fromListType }) => {
      beforeEach(
        ({
          itemId = 123,
          fromListId = 'gid://gitlab/List/1',
          toListId = 'gid://gitlab/List/2',
          originalIssue = { foo: 'bar' },
          originalIndex = 0,
          moveBeforeId = undefined,
          moveAfterId = undefined,
        } = {}) => {
          state = {
            boardLists: {
              [fromListId]: { listType: fromListType },
              [toListId]: { listType: toListType },
            },
            boardItems: { [itemId]: originalIssue },
            boardItemsByListId: { [fromListId]: [123], [toListId]: [] },
          };
          params = { itemId, fromListId, toListId, moveBeforeId, moveAfterId };
          moveMutations = [
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: toListId, moveBeforeId, moveAfterId },
            },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: fromListId, atIndex: originalIndex },
            },
          ];
          undoMutations = [
            { type: types.UPDATE_BOARD_ITEM, payload: originalIssue },
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
            { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: toListId } },
            {
              type: types.ADD_BOARD_ITEM_TO_LIST,
              payload: { itemId, listId: fromListId, atIndex: originalIndex },
            },
          ];
        },
      );

      it('moveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.moveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: moveMutations,
        });
      });

      it('undoMoveIssueCard commits a correct set of actions', () => {
        testAction({
          action: actions.undoMoveIssueCard,
          state,
          payload: getMoveData(state, params),
          expectedMutations: undoMutations,
        });
      });
    });
  });
});

describe('updateMovedIssueCard', () => {
  const label1 = {
    id: 'label1',
  };

  it.each([
    [
      'issue without a label is moved to a label list',
      {
        state: {
          boardLists: {
            from: {},
            to: {
              listType: ListType.label,
              label: label1,
            },
          },
          boardItems: {
            1: {
              labels: [],
            },
          },
        },
        moveData: {
          itemId: 1,
          fromListId: 'from',
          toListId: 'to',
        },
        updatedIssue: { labels: [label1] },
      },
    ],
  ])(
    'should commit UPDATE_BOARD_ITEM with a correctly updated issue data when %s',
    (_, { state, moveData, updatedIssue }) => {
      testAction({
        action: actions.updateMovedIssue,
        payload: moveData,
        state,
        expectedMutations: [{ type: types.UPDATE_BOARD_ITEM, payload: updatedIssue }],
      });
    },
  );
});

describe('updateIssueOrder', () => {
  const issues = {
    436: mockIssue,
    437: mockIssue2,
  };

  const state = {
    boardItems: issues,
    fullBoardId: 'gid://gitlab/Board/1',
  };

  const moveData = {
    itemId: 436,
    fromListId: 'gid://gitlab/List/1',
    toListId: 'gid://gitlab/List/2',
  };

  it('calls mutate with the correct variables', () => {
    const mutationVariables = {
      mutation: issueMoveListMutation,
      variables: {
        projectPath: getProjectPath(mockIssue.referencePath),
        boardId: state.fullBoardId,
        iid: mockIssue.iid,
        fromListId: 1,
        toListId: 2,
        moveBeforeId: undefined,
        moveAfterId: undefined,
      },
    };
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: rawIssue,
          errors: [],
        },
      },
    });

    actions.updateIssueOrder({ state, commit: () => {}, dispatch: () => {} }, { moveData });

    expect(gqlClient.mutate).toHaveBeenCalledWith(mutationVariables);
  });

  it('should commit MUTATE_ISSUE_SUCCESS mutation when successful', () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: rawIssue,
          errors: [],
        },
      },
    });

    testAction(
      actions.updateIssueOrder,
      { moveData },
      state,
      [
        {
          type: types.MUTATE_ISSUE_SUCCESS,
          payload: { issue: rawIssue },
        },
      ],
      [],
    );
  });

  it('should commit SET_ERROR and dispatch undoMoveIssueCard', () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    testAction(
      actions.updateIssueOrder,
      { moveData },
      state,
      [
        {
          type: types.SET_ERROR,
          payload: 'An error occurred while moving the issue. Please try again.',
        },
      ],
      [{ type: 'undoMoveIssueCard', payload: moveData }],
    );
  });
});

describe('setAssignees', () => {
  const node = { username: 'name' };

  describe('when succeeds', () => {
    it('calls the correct mutation with the correct values', (done) => {
      testAction(
        actions.setAssignees,
        { assignees: [node], iid: '1' },
        { commit: () => {} },
        [
          {
            type: 'UPDATE_BOARD_ITEM_BY_ID',
            payload: { prop: 'assignees', itemId: undefined, value: [node] },
          },
        ],
        [],
        done,
      );
    });
  });
});

describe('addListItem', () => {
  it('should commit ADD_BOARD_ITEM_TO_LIST and UPDATE_BOARD_ITEM mutations', () => {
    const payload = {
      list: mockLists[0],
      item: mockIssue,
      position: 0,
    };

    testAction(actions.addListItem, payload, {}, [
      {
        type: types.ADD_BOARD_ITEM_TO_LIST,
        payload: {
          listId: mockLists[0].id,
          itemId: mockIssue.id,
          atIndex: 0,
          inProgress: false,
        },
      },
      { type: types.UPDATE_BOARD_ITEM, payload: mockIssue },
    ]);
  });
});

describe('removeListItem', () => {
  it('should commit REMOVE_BOARD_ITEM_FROM_LIST and REMOVE_BOARD_ITEM mutations', () => {
    const payload = {
      listId: mockLists[0].id,
      itemId: mockIssue.id,
    };

    testAction(actions.removeListItem, payload, {}, [
      { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload },
      { type: types.REMOVE_BOARD_ITEM, payload: mockIssue.id },
    ]);
  });
});

describe('addListNewIssue', () => {
  const state = {
    boardType: 'group',
    fullPath: 'gitlab-org/gitlab',
    boardConfig: {
      labelIds: [],
      assigneeId: null,
      milestoneId: -1,
    },
  };

  const stateWithBoardConfig = {
    boardConfig: {
      labels: [
        {
          id: 5,
          title: 'Test',
          color: '#ff0000',
          description: 'testing;',
          textColor: 'white',
        },
      ],
      assigneeId: 2,
      milestoneId: 3,
    },
  };

  const fakeList = { id: 'gid://gitlab/List/123' };

  it('should add board scope to the issue being created', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue: mockIssue,
          errors: [],
        },
      },
    });

    await actions.addListNewIssue(
      { dispatch: jest.fn(), commit: jest.fn(), state: stateWithBoardConfig },
      { issueInput: mockIssue, list: fakeList },
    );

    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: issueCreateMutation,
      variables: {
        input: formatIssueInput(mockIssue, stateWithBoardConfig.boardConfig),
      },
    });
  });

  it('should add board scope by merging attributes to the issue being created', async () => {
    const issue = {
      ...mockIssue,
      assigneeIds: ['gid://gitlab/User/1'],
      labelIds: ['gid://gitlab/GroupLabel/4'],
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createIssue: {
          issue,
          errors: [],
        },
      },
    });

    const payload = formatIssueInput(issue, stateWithBoardConfig.boardConfig);

    await actions.addListNewIssue(
      { dispatch: jest.fn(), commit: jest.fn(), state: stateWithBoardConfig },
      { issueInput: issue, list: fakeList },
    );

    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: issueCreateMutation,
      variables: {
        input: formatIssueInput(issue, stateWithBoardConfig.boardConfig),
      },
    });
    expect(payload.labelIds).toEqual(['gid://gitlab/GroupLabel/4', 'gid://gitlab/GroupLabel/5']);
    expect(payload.assigneeIds).toEqual(['gid://gitlab/User/1', 'gid://gitlab/User/2']);
  });

  describe('when issue creation mutation request succeeds', () => {
    it('dispatches a correct set of mutations', () => {
      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          createIssue: {
            issue: mockIssue,
            errors: [],
          },
        },
      });

      testAction({
        action: actions.addListNewIssue,
        payload: {
          issueInput: mockIssue,
          list: fakeList,
          placeholderId: 'tmp',
        },
        state,
        expectedActions: [
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: formatIssue({ ...mockIssue, id: 'tmp', isLoading: true }),
              position: 0,
              inProgress: true,
            },
          },
          { type: 'removeListItem', payload: { listId: fakeList.id, itemId: 'tmp' } },
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: formatIssue({ ...mockIssue, id: getIdFromGraphQLId(mockIssue.id) }),
              position: 0,
            },
          },
        ],
      });
    });
  });

  describe('when issue creation mutation request fails', () => {
    it('dispatches a correct set of mutations', () => {
      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          createIssue: {
            issue: mockIssue,
            errors: [{ foo: 'bar' }],
          },
        },
      });

      testAction({
        action: actions.addListNewIssue,
        payload: {
          issueInput: mockIssue,
          list: fakeList,
          placeholderId: 'tmp',
        },
        state,
        expectedActions: [
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: formatIssue({ ...mockIssue, id: 'tmp', isLoading: true }),
              position: 0,
              inProgress: true,
            },
          },
          { type: 'removeListItem', payload: { listId: fakeList.id, itemId: 'tmp' } },
        ],
        expectedMutations: [
          {
            type: types.SET_ERROR,
            payload: 'An error occurred while creating the issue. Please try again.',
          },
        ],
      });
    });
  });
});

describe('setActiveIssueLabels', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeBoardItem: mockIssue };
  const testLabelIds = labels.map((label) => label.id);
  const input = {
    addLabelIds: testLabelIds,
    removeLabelIds: [],
    projectPath: 'h/b',
  };

  it('should assign labels on success', (done) => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { issue: { labels: { nodes: labels } } } } });

    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'labels',
      value: labels,
    };

    testAction(
      actions.setActiveIssueLabels,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveIssueLabels({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveItemSubscribed', () => {
  const state = {
    boardItems: {
      [mockActiveIssue.id]: mockActiveIssue,
    },
    fullPath: 'gitlab-org',
    issuableType: issuableTypes.issue,
  };
  const getters = { activeBoardItem: mockActiveIssue, isEpicBoard: false };
  const subscribedState = true;
  const input = {
    subscribedState,
    projectPath: 'gitlab-org/gitlab-test',
  };

  it('should commit subscribed status', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateIssuableSubscription: {
          issue: {
            subscribed: subscribedState,
          },
          errors: [],
        },
      },
    });

    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'subscribed',
      value: subscribedState,
    };

    testAction(
      actions.setActiveItemSubscribed,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssuableSubscription: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveItemSubscribed({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveItemTitle', () => {
  const state = {
    boardItems: { [mockIssue.id]: mockIssue },
    issuableType: issuableTypes.issue,
    fullPath: 'path/f',
  };
  const getters = { activeBoardItem: mockIssue, isEpicBoard: false };
  const testTitle = 'Test Title';
  const input = {
    title: testTitle,
    projectPath: 'h/b',
  };

  it('should commit title after setting the issue', (done) => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateIssuableTitle: {
          issue: {
            title: testTitle,
          },
          errors: [],
        },
      },
    });

    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'title',
      value: testTitle,
    };

    testAction(
      actions.setActiveItemTitle,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { updateIssue: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveItemTitle({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveItemConfidential', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeBoardItem: mockIssue };

  it('set confidential value on board item', (done) => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'confidential',
      value: true,
    };

    testAction(
      actions.setActiveItemConfidential,
      true,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
      done,
    );
  });
});

describe('fetchGroupProjects', () => {
  const state = {
    fullPath: 'gitlab-org',
  };

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        projects: {
          nodes: mockGroupProjects,
          pageInfo: {
            endCursor: '',
            hasNextPage: false,
          },
        },
      },
    },
  };

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_SUCCESS on success', (done) => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    testAction(
      actions.fetchGroupProjects,
      {},
      state,
      [
        {
          type: types.REQUEST_GROUP_PROJECTS,
          payload: false,
        },
        {
          type: types.RECEIVE_GROUP_PROJECTS_SUCCESS,
          payload: { projects: mockGroupProjects, pageInfo, fetchNext: false },
        },
      ],
      [],
      done,
    );
  });

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_FAILURE on failure', (done) => {
    jest.spyOn(gqlClient, 'query').mockRejectedValue();

    testAction(
      actions.fetchGroupProjects,
      {},
      state,
      [
        {
          type: types.REQUEST_GROUP_PROJECTS,
          payload: false,
        },
        {
          type: types.RECEIVE_GROUP_PROJECTS_FAILURE,
        },
      ],
      [],
      done,
    );
  });
});

describe('setSelectedProject', () => {
  it('should commit mutation SET_SELECTED_PROJECT', (done) => {
    const project = mockGroupProjects[0];

    testAction(
      actions.setSelectedProject,
      project,
      {},
      [
        {
          type: types.SET_SELECTED_PROJECT,
          payload: project,
        },
      ],
      [],
      done,
    );
  });
});

describe('toggleBoardItemMultiSelection', () => {
  const boardItem = mockIssue;
  const boardItem2 = mockIssue2;

  it('should commit mutation ADD_BOARD_ITEM_TO_SELECTION if item is not on selection state', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem,
      { selectedBoardItems: [] },
      [
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: boardItem,
        },
      ],
      [],
    );
  });

  it('should commit mutation REMOVE_BOARD_ITEM_FROM_SELECTION if item is on selection state', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem,
      { selectedBoardItems: [mockIssue] },
      [
        {
          type: types.REMOVE_BOARD_ITEM_FROM_SELECTION,
          payload: boardItem,
        },
      ],
      [],
    );
  });

  it('should additionally commit mutation ADD_BOARD_ITEM_TO_SELECTION for active issue and dispatch unsetActiveId', () => {
    testAction(
      actions.toggleBoardItemMultiSelection,
      boardItem2,
      { activeId: mockActiveIssue.id, activeBoardItem: mockActiveIssue, selectedBoardItems: [] },
      [
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: mockActiveIssue,
        },
        {
          type: types.ADD_BOARD_ITEM_TO_SELECTION,
          payload: boardItem2,
        },
      ],
      [{ type: 'unsetActiveId' }],
    );
  });
});

describe('resetBoardItemMultiSelection', () => {
  it('should commit mutation RESET_BOARD_ITEM_SELECTION', () => {
    testAction({
      action: actions.resetBoardItemMultiSelection,
      state: { selectedBoardItems: [mockIssue] },
      expectedMutations: [
        {
          type: types.RESET_BOARD_ITEM_SELECTION,
        },
      ],
    });
  });
});

describe('toggleBoardItem', () => {
  it('should dispatch resetBoardItemMultiSelection and unsetActiveId when boardItem is the active item', () => {
    testAction({
      action: actions.toggleBoardItem,
      payload: { boardItem: mockIssue },
      state: {
        activeId: mockIssue.id,
      },
      expectedActions: [{ type: 'resetBoardItemMultiSelection' }, { type: 'unsetActiveId' }],
    });
  });

  it('should dispatch resetBoardItemMultiSelection and setActiveId when boardItem is not the active item', () => {
    testAction({
      action: actions.toggleBoardItem,
      payload: { boardItem: mockIssue },
      state: {
        activeId: inactiveId,
      },
      expectedActions: [
        { type: 'resetBoardItemMultiSelection' },
        { type: 'setActiveId', payload: { id: mockIssue.id, sidebarType: ISSUABLE } },
      ],
    });
  });
});

describe('setError', () => {
  it('should commit mutation SET_ERROR', () => {
    testAction({
      action: actions.setError,
      payload: { message: 'mayday' },
      expectedMutations: [
        {
          payload: 'mayday',
          type: types.SET_ERROR,
        },
      ],
    });
  });

  it('should capture error using Sentry when captureError is true', () => {
    jest.spyOn(Sentry, 'captureException');

    const mockError = new Error();
    actions.setError(
      { commit: () => {} },
      {
        message: 'mayday',
        error: mockError,
        captureError: true,
      },
    );

    expect(Sentry.captureException).toHaveBeenNthCalledWith(1, mockError);
  });
});

describe('unsetError', () => {
  it('should commit mutation SET_ERROR with undefined as payload', () => {
    testAction({
      action: actions.unsetError,
      expectedMutations: [
        {
          payload: undefined,
          type: types.SET_ERROR,
        },
      ],
    });
  });
});
