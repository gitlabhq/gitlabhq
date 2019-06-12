import mutations from '~/ide/stores/mutations/project';
import state from '~/ide/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
    localState.projects = { abcproject: { empty_repo: true } };
  });

  describe('TOGGLE_EMPTY_STATE', () => {
    it('sets empty_repo for project to passed value', () => {
      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: 'abcproject', value: false });

      expect(localState.projects.abcproject.empty_repo).toBe(false);

      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: 'abcproject', value: true });

      expect(localState.projects.abcproject.empty_repo).toBe(true);
    });
  });
});
