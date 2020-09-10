import testAction from 'helpers/vuex_action_helper';
import {
  mockListsWithModel,
  mockLists,
  mockIssue,
  mockIssue2,
  mockIssueWithModel,
  mockIssue2WithModel,
  rawIssue,
} from '../mock_data';
import actions, { gqlClient } from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import { inactiveId, ListType } from '~/boards/constants';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

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
  it('should commit mutation SET_FILTERS', done => {
    const state = {
      filters: {},
    };

    const filters = { labelName: 'label' };

    testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: filters }],
      [],
      done,
    );
  });
});

describe('setActiveId', () => {
  it('should commit mutation SET_ACTIVE_ID', done => {
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

describe('showWelcomeList', () => {
  it('should dispatch addList action', done => {
    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'backlog' }, { type: 'closed' }],
    };

    const blankList = {
      id: 'blank',
      listType: ListType.blank,
      title: 'Welcome to your issue board!',
      position: 0,
    };

    testAction(
      actions.showWelcomeList,
      {},
      state,
      [],
      [{ type: 'addList', payload: blankList }],
      done,
    );
  });
});

describe('generateDefaultLists', () => {
  expectNotImplemented(actions.generateDefaultLists);
});

describe('createList', () => {
  it('should dispatch addList action when creating backlog list', done => {
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

    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
    };

    testAction(
      actions.createList,
      { backlog: true },
      state,
      [],
      [{ type: 'addList', payload: { ...backlogList, id: 1 } }],
      done,
    );
  });

  it('should commit CREATE_LIST_FAILURE mutation when API returns an error', done => {
    jest.spyOn(gqlClient, 'mutate').mockReturnValue(
      Promise.resolve({
        data: {
          boardListCreate: {
            list: {},
            errors: [{ foo: 'bar' }],
          },
        },
      }),
    );

    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
    };

    testAction(
      actions.createList,
      { backlog: true },
      state,
      [{ type: types.CREATE_LIST_FAILURE }],
      [],
      done,
    );
  });
});

describe('moveList', () => {
  it('should commit MOVE_LIST mutation and dispatch updateList action', done => {
    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: mockListsWithModel,
    };

    testAction(
      actions.moveList,
      { listId: 'gid://gitlab/List/1', newIndex: 1, adjustmentValue: 1 },
      state,
      [
        {
          type: types.MOVE_LIST,
          payload: { movedList: mockListsWithModel[0], listAtNewIndex: mockListsWithModel[1] },
        },
      ],
      [
        {
          type: 'updateList',
          payload: { listId: 'gid://gitlab/List/1', position: 0, backupList: mockListsWithModel },
        },
      ],
      done,
    );
  });
});

describe('updateList', () => {
  it('should commit UPDATE_LIST_FAILURE mutation when API returns an error', done => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        updateBoardList: {
          list: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    const state = {
      endpoints: { fullPath: 'gitlab-org', boardId: '1' },
      boardType: 'group',
      disabled: false,
      boardLists: [{ type: 'closed' }],
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

describe('deleteList', () => {
  expectNotImplemented(actions.deleteList);
});

describe('fetchIssuesForList', () => {
  expectNotImplemented(actions.fetchIssuesForList);
});

describe('moveIssue', () => {
  const listIssues = {
    'gid://gitlab/List/1': [mockIssue.id, mockIssue2.id],
    'gid://gitlab/List/2': [],
  };

  const issues = {
    '1': mockIssueWithModel,
    '2': mockIssue2WithModel,
  };

  const state = {
    endpoints: { fullPath: 'gitlab-org', boardId: '1' },
    boardType: 'group',
    disabled: false,
    boardLists: mockListsWithModel,
    issuesByListId: listIssues,
    issues,
  };

  it('should commit MOVE_ISSUE mutation and MOVE_ISSUE_SUCCESS mutation when successful', done => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: rawIssue,
          errors: [],
        },
      },
    });

    testAction(
      actions.moveIssue,
      {
        issueId: mockIssue.id,
        issueIid: mockIssue.iid,
        issuePath: mockIssue.referencePath,
        fromListId: 'gid://gitlab/List/1',
        toListId: 'gid://gitlab/List/2',
      },
      state,
      [
        {
          type: types.MOVE_ISSUE,
          payload: {
            originalIssue: mockIssueWithModel,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
          },
        },
        {
          type: types.MOVE_ISSUE_SUCCESS,
          payload: { issue: rawIssue },
        },
      ],
      [],
      done,
    );
  });

  it('should commit MOVE_ISSUE mutation and MOVE_ISSUE_FAILURE mutation when unsuccessful', done => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        issueMoveList: {
          issue: {},
          errors: [{ foo: 'bar' }],
        },
      },
    });

    testAction(
      actions.moveIssue,
      {
        issueId: mockIssue.id,
        issueIid: mockIssue.iid,
        issuePath: mockIssue.referencePath,
        fromListId: 'gid://gitlab/List/1',
        toListId: 'gid://gitlab/List/2',
      },
      state,
      [
        {
          type: types.MOVE_ISSUE,
          payload: {
            originalIssue: mockIssueWithModel,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
          },
        },
        {
          type: types.MOVE_ISSUE_FAILURE,
          payload: {
            originalIssue: mockIssueWithModel,
            fromListId: 'gid://gitlab/List/1',
            toListId: 'gid://gitlab/List/2',
            originalIndex: 0,
          },
        },
      ],
      [],
      done,
    );
  });
});

describe('createNewIssue', () => {
  expectNotImplemented(actions.createNewIssue);
});

describe('addListIssue', () => {
  it('should commit UPDATE_LIST_FAILURE mutation when API returns an error', done => {
    const payload = {
      list: mockLists[0],
      issue: mockIssue,
      position: 0,
    };

    testAction(
      actions.addListIssue,
      payload,
      {},
      [{ type: types.ADD_ISSUE_TO_LIST, payload }],
      [],
      done,
    );
  });
});

describe('addListIssueFailure', () => {
  it('should commit UPDATE_LIST_FAILURE mutation when API returns an error', done => {
    const payload = {
      list: mockLists[0],
      issue: mockIssue,
    };

    testAction(
      actions.addListIssueFailure,
      payload,
      {},
      [{ type: types.ADD_ISSUE_TO_LIST_FAILURE, payload }],
      [],
      done,
    );
  });
});

describe('fetchBacklog', () => {
  expectNotImplemented(actions.fetchBacklog);
});

describe('bulkUpdateIssues', () => {
  expectNotImplemented(actions.bulkUpdateIssues);
});

describe('fetchIssue', () => {
  expectNotImplemented(actions.fetchIssue);
});

describe('toggleIssueSubscription', () => {
  expectNotImplemented(actions.toggleIssueSubscription);
});

describe('showPage', () => {
  expectNotImplemented(actions.showPage);
});

describe('toggleEmptyState', () => {
  expectNotImplemented(actions.toggleEmptyState);
});
