import commitState from '~/ide/stores/modules/commit/state';
import mutations from '~/ide/stores/modules/commit/mutations';

describe('IDE commit module mutations', () => {
  let state;

  beforeEach(() => {
    state = commitState();
  });

  describe('UPDATE_COMMIT_MESSAGE', () => {
    it('updates commitMessage', () => {
      mutations.UPDATE_COMMIT_MESSAGE(state, 'testing');

      expect(state.commitMessage).toBe('testing');
    });
  });

  describe('UPDATE_COMMIT_ACTION', () => {
    it('updates commitAction', () => {
      mutations.UPDATE_COMMIT_ACTION(state, 'testing');

      expect(state.commitAction).toBe('testing');
    });
  });

  describe('UPDATE_NEW_BRANCH_NAME', () => {
    it('updates newBranchName', () => {
      mutations.UPDATE_NEW_BRANCH_NAME(state, 'testing');

      expect(state.newBranchName).toBe('testing');
    });
  });

  describe('UPDATE_LOADING', () => {
    it('updates submitCommitLoading', () => {
      mutations.UPDATE_LOADING(state, true);

      expect(state.submitCommitLoading).toBeTruthy();
    });
  });
});
