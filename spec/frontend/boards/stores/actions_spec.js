import testAction from 'helpers/vuex_action_helper';
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

describe('updateList', () => {
  expectNotImplemented(actions.updateList);
});

describe('deleteList', () => {
  expectNotImplemented(actions.deleteList);
});

describe('fetchIssuesForList', () => {
  expectNotImplemented(actions.fetchIssuesForList);
});

describe('moveIssue', () => {
  expectNotImplemented(actions.moveIssue);
});

describe('createNewIssue', () => {
  expectNotImplemented(actions.createNewIssue);
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
