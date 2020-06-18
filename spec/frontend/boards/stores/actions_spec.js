import actions from '~/boards/stores/actions';
import * as types from '~/boards/stores/mutation_types';
import testAction from 'helpers/vuex_action_helper';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('setEndpoints', () => {
  it('sets endpoints object', () => {
    const mockEndpoints = {
      foo: 'bar',
      bar: 'baz',
    };

    return testAction(
      actions.setEndpoints,
      mockEndpoints,
      {},
      [{ type: types.SET_ENDPOINTS, payload: mockEndpoints }],
      [],
    );
  });
});

describe('fetchLists', () => {
  expectNotImplemented(actions.fetchLists);
});

describe('generateDefaultLists', () => {
  expectNotImplemented(actions.generateDefaultLists);
});

describe('createList', () => {
  expectNotImplemented(actions.createList);
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
