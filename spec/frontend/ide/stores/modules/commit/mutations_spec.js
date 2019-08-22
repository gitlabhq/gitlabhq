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
      mutations.UPDATE_COMMIT_ACTION(state, { commitAction: 'testing' });

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

  describe('TOGGLE_SHOULD_CREATE_MR', () => {
    it('changes shouldCreateMR to true when initial state is false', () => {
      state.shouldCreateMR = false;
      mutations.TOGGLE_SHOULD_CREATE_MR(state);

      expect(state.shouldCreateMR).toBe(true);
    });

    it('changes shouldCreateMR to false when initial state is true', () => {
      state.shouldCreateMR = true;
      mutations.TOGGLE_SHOULD_CREATE_MR(state);

      expect(state.shouldCreateMR).toBe(false);
    });

    it('sets shouldCreateMR to given value when passed in', () => {
      state.shouldCreateMR = false;
      mutations.TOGGLE_SHOULD_CREATE_MR(state, false);

      expect(state.shouldCreateMR).toBe(false);
    });
  });
});
