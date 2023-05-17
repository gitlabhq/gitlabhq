import * as Sentry from '@sentry/browser';
import { cloneDeep } from 'lodash';
import Vue from 'vue';
import Vuex from 'vuex';
import { inactiveId, ISSUABLE, ListType, DraggableItemTypes } from 'ee_else_ce/boards/constants';
import issueMoveListMutation from 'ee_else_ce/boards/graphql/issue_move_list.mutation.graphql';
import testAction from 'helpers/vuex_action_helper';
import {
  formatListIssues,
  formatBoardLists,
  formatIssueInput,
  formatIssue,
  getMoveData,
  updateListPosition,
} from 'ee_else_ce/boards/boards_util';
import { defaultClient as gqlClient } from '~/graphql_shared/issuable_client';
import destroyBoardListMutation from '~/boards/graphql/board_list_destroy.mutation.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import actions from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import mutations from '~/boards/stores/mutations';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

import projectBoardMilestones from '~/boards/graphql/project_board_milestones.query.graphql';
import groupBoardMilestones from '~/boards/graphql/group_board_milestones.query.graphql';
import {
  mockBoard,
  mockBoardConfig,
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
  mockMilestones,
} from '../mock_data';

jest.mock('~/alert');

// We need this helper to make sure projectPath is including
// subgroups when the movIssue action is called.
const getProjectPath = (path) => path.split('#')[0];

Vue.use(Vuex);

beforeEach(() => {
  window.gon = { features: {} };
});

describe('fetchBoard', () => {
  const payload = {
    fullPath: 'gitlab-org',
    fullBoardId: 'gid://gitlab/Board/1',
    boardType: 'project',
  };

  const queryResponse = {
    data: {
      workspace: {
        board: mockBoard,
      },
    },
  };

  it('should commit mutation REQUEST_CURRENT_BOARD and dispatch setBoard on success', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction({
      action: actions.fetchBoard,
      payload,
      expectedMutations: [
        {
          type: types.REQUEST_CURRENT_BOARD,
        },
      ],
      expectedActions: [{ type: 'setBoard', payload: mockBoard }],
    });
  });

  it('should commit mutation RECEIVE_BOARD_FAILURE on failure', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    await testAction({
      action: actions.fetchBoard,
      payload,
      expectedMutations: [
        {
          type: types.REQUEST_CURRENT_BOARD,
        },
        {
          type: types.RECEIVE_BOARD_FAILURE,
        },
      ],
    });
  });
});

describe('setInitialBoardData', () => {
  it('sets data object', () => {
    const mockData = {
      foo: 'bar',
      bar: 'baz',
    };

    return testAction({
      action: actions.setInitialBoardData,
      payload: mockData,
      expectedMutations: [{ type: types.SET_INITIAL_BOARD_DATA, payload: mockData }],
    });
  });
});

describe('setBoardConfig', () => {
  it('sets board config object from board object', () => {
    return testAction({
      action: actions.setBoardConfig,
      payload: mockBoard,
      expectedMutations: [{ type: types.SET_BOARD_CONFIG, payload: mockBoardConfig }],
    });
  });
});

describe('setBoard', () => {
  it('dispatches setBoardConfig', () => {
    return testAction({
      action: actions.setBoard,
      payload: mockBoard,
      expectedMutations: [{ type: types.RECEIVE_BOARD_SUCCESS, payload: mockBoard }],
      expectedActions: [
        { type: 'setBoardConfig', payload: mockBoard },
        { type: 'performSearch', payload: { resetLists: true } },
      ],
    });
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
      "and use 'assigneeWildcardId' as filter variable for 'assigneeId' param",
      {
        filters: { assigneeId: 'None' },
        filterVariables: { assigneeWildcardId: 'NONE', not: {} },
      },
    ],
  ])('should commit mutation SET_FILTERS %s', (_, { filters, filterVariables }) => {
    const state = {
      filters: {},
      issuableType: TYPE_ISSUE,
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
  it('should dispatch setFilters, fetchLists and resetIssues action', () => {
    return testAction(
      actions.performSearch,
      {},
      {},
      [],
      [
        { type: 'setFilters', payload: {} },
        { type: 'fetchLists', payload: { resetLists: false } },
        { type: 'resetIssues' },
      ],
    );
  });
});

describe('setActiveId', () => {
  it('should commit mutation SET_ACTIVE_ID', () => {
    const state = {
      activeId: inactiveId,
    };

    return testAction(
      actions.setActiveId,
      { id: 1, sidebarType: 'something' },
      state,
      [{ type: types.SET_ACTIVE_ID, payload: { id: 1, sidebarType: 'something' } }],
      [],
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

  it('should commit mutations RECEIVE_BOARD_LISTS_SUCCESS on success', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    return testAction(
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
    );
  });

  it('should commit mutations RECEIVE_BOARD_LISTS_FAILURE on failure', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    return testAction(
      actions.fetchLists,
      {},
      state,
      [
        {
          type: types.RECEIVE_BOARD_LISTS_FAILURE,
        },
      ],
      [],
    );
  });

  it('dispatch createList action when backlog list does not exist and is not hidden', () => {
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

    return testAction(
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
    );
  });

  it.each`
    issuableType  | boardType            | fullBoardId               | isGroup  | isProject
    ${TYPE_ISSUE} | ${WORKSPACE_GROUP}   | ${'gid://gitlab/Board/1'} | ${true}  | ${false}
    ${TYPE_ISSUE} | ${WORKSPACE_PROJECT} | ${'gid://gitlab/Board/1'} | ${false} | ${true}
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
        fullPath: 'gitlab-org',
        boardId: fullBoardId,
        filters: {},
        isGroup,
        isProject,
      };

      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchLists({ commit, state, dispatch });

      expect(gqlClient.query).toHaveBeenCalledWith(expect.objectContaining({ variables }));
    },
  );
});

describe('fetchMilestones', () => {
  const queryResponse = {
    data: {
      workspace: {
        milestones: {
          nodes: mockMilestones,
        },
      },
    },
  };

  const queryErrors = {
    data: {
      workspace: {
        errors: ['You cannot view these milestones'],
        milestones: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'project',
      fullPath: 'gitlab-org/gitlab',
      milestones: [],
      milestonesLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('throws error if state.boardType is not group or project', () => {
    const store = createStore({
      state: {
        boardType: 'invalid',
      },
    });

    expect(() => actions.fetchMilestones(store)).toThrow(new Error('Unknown board type'));
  });

  it.each([
    [
      'project',
      {
        query: projectBoardMilestones,
        variables: { fullPath: 'gitlab-org/gitlab' },
      },
    ],
    [
      'group',
      {
        query: groupBoardMilestones,
        variables: { fullPath: 'gitlab-org/gitlab' },
      },
    ],
  ])(
    'when boardType is %s it calls fetchMilestones with the correct query and variables',
    (boardType, variables) => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      store.state.boardType = boardType;

      actions.fetchMilestones(store);

      expect(gqlClient.query).toHaveBeenCalledWith(variables);
    },
  );

  it('sets milestonesLoading to true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchMilestones(store);

    expect(store.state.milestonesLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.milestones from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchMilestones(store);

      expect(store.state.milestonesLoading).toBe(false);
      expect(store.state.milestones).toBe(mockMilestones);
    });
  });

  describe('failure', () => {
    it('sets state.milestones from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchMilestones(store)).rejects.toThrow();

      expect(store.state.milestonesLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load milestones.');
    });
  });
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
    const state = { boardType: 'group' };

    await actions.fetchLabels({ state, commit });

    expect(commit).toHaveBeenCalledWith(types.RECEIVE_LABELS_SUCCESS, labels);
  });
});

describe('moveList', () => {
  const backlogListId = 'gid://1';
  const closedListId = 'gid://5';

  const boardLists1 = {
    'gid://3': { listType: '', position: 0 },
    'gid://4': { listType: '', position: 1 },
    'gid://5': { listType: '', position: 2 },
  };

  const boardLists2 = {
    [backlogListId]: { listType: ListType.backlog, position: -Infinity },
    [closedListId]: { listType: ListType.closed, position: Infinity },
    ...cloneDeep(boardLists1),
  };

  const movableListsOrder = ['gid://3', 'gid://4', 'gid://5'];
  const allListsOrder = [backlogListId, ...movableListsOrder, closedListId];

  it(`should not handle the event if the dragged item is not a "${DraggableItemTypes.list}"`, () => {
    return testAction({
      action: actions.moveList,
      payload: {
        item: { dataset: { listId: '', draggableItemType: DraggableItemTypes.card } },
        to: {
          children: [],
        },
      },
      state: {},
      expectedMutations: [],
      expectedActions: [],
    });
  });

  describe.each`
    draggableFrom | draggableTo | boardLists     | boardListsOrder      | expectedMovableListsOrder
    ${0}          | ${2}        | ${boardLists1} | ${movableListsOrder} | ${['gid://4', 'gid://5', 'gid://3']}
    ${2}          | ${0}        | ${boardLists1} | ${movableListsOrder} | ${['gid://5', 'gid://3', 'gid://4']}
    ${0}          | ${1}        | ${boardLists1} | ${movableListsOrder} | ${['gid://4', 'gid://3', 'gid://5']}
    ${1}          | ${2}        | ${boardLists1} | ${movableListsOrder} | ${['gid://3', 'gid://5', 'gid://4']}
    ${2}          | ${1}        | ${boardLists1} | ${movableListsOrder} | ${['gid://3', 'gid://5', 'gid://4']}
    ${1}          | ${3}        | ${boardLists2} | ${allListsOrder}     | ${['gid://4', 'gid://5', 'gid://3']}
    ${3}          | ${1}        | ${boardLists2} | ${allListsOrder}     | ${['gid://5', 'gid://3', 'gid://4']}
    ${1}          | ${2}        | ${boardLists2} | ${allListsOrder}     | ${['gid://4', 'gid://3', 'gid://5']}
    ${2}          | ${3}        | ${boardLists2} | ${allListsOrder}     | ${['gid://3', 'gid://5', 'gid://4']}
    ${3}          | ${2}        | ${boardLists2} | ${allListsOrder}     | ${['gid://3', 'gid://5', 'gid://4']}
  `(
    'when moving a list from position $draggableFrom to $draggableTo with lists $boardListsOrder',
    ({ draggableFrom, draggableTo, boardLists, boardListsOrder, expectedMovableListsOrder }) => {
      const movedListId = boardListsOrder[draggableFrom];
      const displacedListId = boardListsOrder[draggableTo];
      const buildDraggablePayload = () => {
        return {
          item: {
            dataset: {
              listId: boardListsOrder[draggableFrom],
              draggableItemType: DraggableItemTypes.list,
            },
          },
          newIndex: draggableTo,
          to: {
            children: boardListsOrder.map((listId) => ({ dataset: { listId } })),
          },
        };
      };

      it('should commit MOVE_LIST mutations and dispatch updateList action with correct payloads', () => {
        return testAction({
          action: actions.moveList,
          payload: buildDraggablePayload(),
          state: { boardLists },
          expectedMutations: [
            {
              type: types.MOVE_LISTS,
              payload: expectedMovableListsOrder.map((listId, i) => ({ listId, position: i })),
            },
          ],
          expectedActions: [
            {
              type: 'updateList',
              payload: {
                listId: movedListId,
                position: movableListsOrder.findIndex((i) => i === displacedListId),
              },
            },
          ],
        });
      });
    },
  );

  describe('when moving from and to the same position', () => {
    it('should not commit MOVE_LIST and should not dispatch updateList', () => {
      const listId = 'gid://1000';

      return testAction({
        action: actions.moveList,
        payload: {
          item: { dataset: { listId, draggbaleItemType: DraggableItemTypes.list } },
          newIndex: 0,
          to: {
            children: [{ dataset: { listId } }],
          },
        },
        state: { boardLists: { [listId]: { position: 0 } } },
        expectedMutations: [],
        expectedActions: [],
      });
    });
  });
});

describe('updateList', () => {
  const listId = 'gid://gitlab/List/1';
  const createState = (boardItemsByListId = {}) => ({
    fullPath: 'gitlab-org',
    fullBoardId: 'gid://gitlab/Board/1',
    boardType: 'group',
    disabled: false,
    boardLists: [{ type: 'closed' }],
    issuableType: TYPE_ISSUE,
    boardItemsByListId,
  });

  describe('when state doesnt have list items', () => {
    it('calls fetchItemsByList', async () => {
      const dispatch = jest.fn();

      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          updateBoardList: {
            errors: [],
            list: {
              id: listId,
            },
          },
        },
      });

      await actions.updateList({ commit: () => {}, state: createState(), dispatch }, { listId });

      expect(dispatch.mock.calls).toEqual([['fetchItemsForList', { listId }]]);
    });
  });

  describe('when state has list items', () => {
    it('doesnt call fetchItemsByList', async () => {
      const commit = jest.fn();
      const dispatch = jest.fn();

      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          updateBoardList: {
            errors: [],
            list: {
              id: listId,
            },
          },
        },
      });

      await actions.updateList(
        { commit, state: createState({ [listId]: [] }), dispatch },
        { listId },
      );

      expect(dispatch.mock.calls).toEqual([]);
    });
  });

  it('should dispatch handleUpdateListFailure when API returns an error', () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateBoardList: {
          list: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    return testAction(
      actions.updateList,
      { listId: 'gid://gitlab/List/1', position: 1 },
      createState(),
      [],
      [{ type: 'handleUpdateListFailure' }],
    );
  });
});

describe('handleUpdateListFailure', () => {
  it('should dispatch fetchLists action and commit SET_ERROR mutation', async () => {
    await testAction({
      action: actions.handleUpdateListFailure,
      expectedMutations: [
        {
          type: types.SET_ERROR,
          payload: 'An error occurred while updating the board list. Please try again.',
        },
      ],
      expectedActions: [{ type: 'fetchLists' }],
    });
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
      issuableType: TYPE_ISSUE,
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

  describe('when list id is undefined', () => {
    it('does not call the query', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchItemsForList(
        { state, getters: () => {}, commit: () => {} },
        { listId: undefined },
      );

      expect(gqlClient.query).toHaveBeenCalledTimes(0);
    });
  });

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_SUCCESS on success', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    return testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
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
    );
  });

  it('should commit mutations REQUEST_ITEMS_FOR_LIST and RECEIVE_ITEMS_FOR_LIST_FAILURE on failure', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    return testAction(
      actions.fetchItemsForList,
      { listId },
      state,
      [
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        { type: types.RECEIVE_ITEMS_FOR_LIST_FAILURE, payload: listId },
      ],
      [],
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
  describe('card should move without cloning', () => {
    let state;
    let params;
    let moveMutations;
    let undoMutations;

    describe('when re-ordering card', () => {
      beforeEach(() => {
        const itemId = 123;
        const fromListId = 'gid://gitlab/List/1';
        const toListId = 'gid://gitlab/List/1';
        const originalIssue = { foo: 'bar' };
        const originalIndex = 0;
        const moveBeforeId = undefined;
        const moveAfterId = undefined;
        const allItemsLoadedInList = true;
        const listPosition = undefined;

        state = {
          boardLists: {
            [toListId]: { listType: ListType.backlog },
            [fromListId]: { listType: ListType.backlog },
          },
          boardItems: { [itemId]: originalIssue },
          boardItemsByListId: { [fromListId]: [123] },
        };
        params = {
          itemId,
          fromListId,
          toListId,
          moveBeforeId,
          moveAfterId,
          listPosition,
          allItemsLoadedInList,
        };
        moveMutations = [
          { type: types.REMOVE_BOARD_ITEM_FROM_LIST, payload: { itemId, listId: fromListId } },
          {
            type: types.ADD_BOARD_ITEM_TO_LIST,
            payload: {
              itemId,
              listId: toListId,
              moveBeforeId,
              moveAfterId,
              listPosition,
              allItemsLoadedInList,
              atIndex: originalIndex,
            },
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
      });

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
      beforeEach(() => {
        const itemId = 123;
        const fromListId = 'gid://gitlab/List/1';
        const toListId = 'gid://gitlab/List/2';
        const originalIssue = { foo: 'bar' };
        const originalIndex = 0;
        const moveBeforeId = undefined;
        const moveAfterId = undefined;

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
      });

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
      beforeEach(() => {
        const itemId = 123;
        const fromListId = 'gid://gitlab/List/1';
        const toListId = 'gid://gitlab/List/2';
        const originalIssue = { foo: 'bar' };
        const originalIndex = 0;
        const moveBeforeId = undefined;
        const moveAfterId = undefined;

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
      });

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
    [mockIssue.id]: mockIssue,
    [mockIssue2.id]: mockIssue2,
  };

  const state = {
    boardItems: issues,
    fullBoardId: 'gid://gitlab/Board/1',
  };

  const moveData = {
    itemId: mockIssue.id,
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
      update: expect.anything(),
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
          type: types.MUTATE_ISSUE_IN_PROGRESS,
          payload: true,
        },
        {
          type: types.MUTATE_ISSUE_SUCCESS,
          payload: { issue: rawIssue },
        },
        {
          type: types.MUTATE_ISSUE_IN_PROGRESS,
          payload: false,
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
          type: types.MUTATE_ISSUE_IN_PROGRESS,
          payload: true,
        },
        {
          type: types.MUTATE_ISSUE_IN_PROGRESS,
          payload: false,
        },
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
    it('calls the correct mutation with the correct values', () => {
      return testAction(
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
      inProgress: true,
    };

    testAction(
      actions.addListItem,
      payload,
      {},
      [
        {
          type: types.ADD_BOARD_ITEM_TO_LIST,
          payload: {
            listId: mockLists[0].id,
            itemId: mockIssue.id,
            atIndex: 0,
            inProgress: true,
          },
        },
        { type: types.UPDATE_BOARD_ITEM, payload: mockIssue },
      ],
      [],
    );
  });

  it('should commit ADD_BOARD_ITEM_TO_LIST and UPDATE_BOARD_ITEM mutations, dispatch setActiveId action when inProgress is false', () => {
    const payload = {
      list: mockLists[0],
      item: mockIssue,
      position: 0,
    };

    testAction(
      actions.addListItem,
      payload,
      {},
      [
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
      ],
      [{ type: 'setActiveId', payload: { id: mockIssue.id, sidebarType: ISSUABLE } }],
    );
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
      update: expect.anything(),
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
      update: expect.anything(),
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
              item: formatIssue(mockIssue),
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
  const getters = { activeBoardItem: { ...mockIssue, labels } };
  const testLabelIds = labels.map((label) => label.id);
  const input = {
    labelIds: testLabelIds,
    removeLabelIds: [],
    projectPath: 'h/b',
    labels,
  };

  it('should assign labels', () => {
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
    );
  });

  it('should remove label', () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'labels',
      value: [labels[1]],
    };

    testAction(
      actions.setActiveIssueLabels,
      { ...input, removeLabelIds: [getIdFromGraphQLId(labels[0].id)] },
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
    );
  });
});

describe('setActiveItemSubscribed', () => {
  const state = {
    boardItems: {
      [mockActiveIssue.id]: mockActiveIssue,
    },
    fullPath: 'gitlab-org',
    issuableType: TYPE_ISSUE,
  };
  const getters = { activeBoardItem: mockActiveIssue, isEpicBoard: false };
  const subscribedState = true;
  const input = {
    subscribedState,
    projectPath: 'gitlab-org/gitlab-test',
  };

  it('should commit subscribed status', () => {
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

    return testAction(
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
    issuableType: TYPE_ISSUE,
    fullPath: 'path/f',
  };
  const getters = { activeBoardItem: mockIssue, isEpicBoard: false };
  const testTitle = 'Test Title';
  const input = {
    title: testTitle,
    projectPath: 'h/b',
  };

  it('should commit title after setting the issue', () => {
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

    return testAction(
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

  it('set confidential value on board item', () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'confidential',
      value: true,
    };

    return testAction(
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

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_SUCCESS on success', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    return testAction(
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
    );
  });

  it('should commit mutations REQUEST_GROUP_PROJECTS and RECEIVE_GROUP_PROJECTS_FAILURE on failure', () => {
    jest.spyOn(gqlClient, 'query').mockRejectedValue();

    return testAction(
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
    );
  });
});

describe('setSelectedProject', () => {
  it('should commit mutation SET_SELECTED_PROJECT', () => {
    const project = mockGroupProjects[0];

    return testAction(
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
