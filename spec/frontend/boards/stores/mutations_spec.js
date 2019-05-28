import mutations from '~/boards/stores/mutations';

const expectNotImplemented = action => {
  it('is not implemented', () => {
    expect(action).toThrow(new Error('Not implemented!'));
  });
};

describe('SET_ENDPOINTS', () => {
  expectNotImplemented(mutations.SET_ENDPOINTS);
});

describe('REQUEST_ADD_LIST', () => {
  expectNotImplemented(mutations.REQUEST_ADD_LIST);
});

describe('RECEIVE_ADD_LIST_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_LIST_SUCCESS);
});

describe('RECEIVE_ADD_LIST_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_LIST_ERROR);
});

describe('REQUEST_UPDATE_LIST', () => {
  expectNotImplemented(mutations.REQUEST_UPDATE_LIST);
});

describe('RECEIVE_UPDATE_LIST_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_UPDATE_LIST_SUCCESS);
});

describe('RECEIVE_UPDATE_LIST_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_UPDATE_LIST_ERROR);
});

describe('REQUEST_REMOVE_LIST', () => {
  expectNotImplemented(mutations.REQUEST_REMOVE_LIST);
});

describe('RECEIVE_REMOVE_LIST_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_LIST_SUCCESS);
});

describe('RECEIVE_REMOVE_LIST_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_REMOVE_LIST_ERROR);
});

describe('REQUEST_ADD_ISSUE', () => {
  expectNotImplemented(mutations.REQUEST_ADD_ISSUE);
});

describe('RECEIVE_ADD_ISSUE_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_ISSUE_SUCCESS);
});

describe('RECEIVE_ADD_ISSUE_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_ADD_ISSUE_ERROR);
});

describe('REQUEST_MOVE_ISSUE', () => {
  expectNotImplemented(mutations.REQUEST_MOVE_ISSUE);
});

describe('RECEIVE_MOVE_ISSUE_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_MOVE_ISSUE_SUCCESS);
});

describe('RECEIVE_MOVE_ISSUE_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_MOVE_ISSUE_ERROR);
});

describe('REQUEST_UPDATE_ISSUE', () => {
  expectNotImplemented(mutations.REQUEST_UPDATE_ISSUE);
});

describe('RECEIVE_UPDATE_ISSUE_SUCCESS', () => {
  expectNotImplemented(mutations.RECEIVE_UPDATE_ISSUE_SUCCESS);
});

describe('RECEIVE_UPDATE_ISSUE_ERROR', () => {
  expectNotImplemented(mutations.RECEIVE_UPDATE_ISSUE_ERROR);
});

describe('SET_CURRENT_PAGE', () => {
  expectNotImplemented(mutations.SET_CURRENT_PAGE);
});

describe('TOGGLE_EMPTY_STATE', () => {
  expectNotImplemented(mutations.TOGGLE_EMPTY_STATE);
});
