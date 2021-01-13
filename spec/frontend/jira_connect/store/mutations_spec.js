import mutations from '~/jira_connect/store/mutations';
import state from '~/jira_connect/store/state';

describe('JiraConnect store mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_ERROR_MESSAGE', () => {
    it('sets error message', () => {
      mutations.SET_ERROR_MESSAGE(localState, 'test error');

      expect(localState.errorMessage).toBe('test error');
    });
  });
});
