import mutations from '~/ide/stores/mutations/project';
import state from '~/ide/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;
  const nonExistentProj = 'nonexistent';
  const existingProj = 'abcproject';

  beforeEach(() => {
    localState = state();
    localState.projects = { [existingProj]: { empty_repo: true } };
  });

  describe('TOGGLE_EMPTY_STATE', () => {
    it('sets empty_repo for project to passed value', () => {
      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: existingProj, value: false });

      expect(localState.projects[existingProj].empty_repo).toBe(false);

      mutations.TOGGLE_EMPTY_STATE(localState, { projectPath: existingProj, value: true });

      expect(localState.projects[existingProj].empty_repo).toBe(true);
    });
  });

  describe('UPDATE_PROJECT', () => {
    it.each`
      desc                                                  | projectPath        | props                    | expectedProps
      ${'extends existing project with the passed props'}   | ${existingProj}    | ${{ foo1: 'bar' }}       | ${{ foo1: 'bar' }}
      ${'overrides existing props on the exsiting project'} | ${existingProj}    | ${{ empty_repo: false }} | ${{ empty_repo: false }}
      ${'does nothing if the project does not exist'}       | ${nonExistentProj} | ${{ foo2: 'bar' }}       | ${undefined}
      ${'does nothing if project is not passed'}            | ${undefined}       | ${{ foo3: 'bar' }}       | ${undefined}
      ${'does nothing if the props are not passed'}         | ${existingProj}    | ${undefined}             | ${{}}
      ${'does nothing if the props are empty'}              | ${existingProj}    | ${{}}                    | ${{}}
    `('$desc', ({ projectPath, props, expectedProps } = {}) => {
      const origProject = localState.projects[projectPath];

      mutations.UPDATE_PROJECT(localState, { projectPath, props });

      if (!expectedProps) {
        expect(localState.projects[projectPath]).toBeUndefined();
      } else {
        expect(localState.projects[projectPath]).toEqual({
          ...origProject,
          ...expectedProps,
        });
      }
    });
  });
});
