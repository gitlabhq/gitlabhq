import mutations from '~/ide/stores/mutations/branch';
import state from '~/ide/stores/state';

describe('Multi-file store branch mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_CURRENT_BRANCH', () => {
    it('sets currentBranch', () => {
      mutations.SET_CURRENT_BRANCH(localState, 'main');

      expect(localState.currentBranchId).toBe('main');
    });
  });

  describe('SET_BRANCH_COMMIT', () => {
    it('sets the last commit on current project', () => {
      localState.projects = {
        Example: {
          branches: {
            main: {},
          },
        },
      };

      mutations.SET_BRANCH_COMMIT(localState, {
        projectId: 'Example',
        branchId: 'main',
        commit: {
          title: 'Example commit',
        },
      });

      expect(localState.projects.Example.branches.main.commit.title).toBe('Example commit');
    });
  });

  describe('SET_BRANCH_WORKING_REFERENCE', () => {
    beforeEach(() => {
      localState.projects = {
        Foo: {
          branches: {
            bar: {},
          },
        },
      };
    });

    it('sets workingReference for existing branch', () => {
      mutations.SET_BRANCH_WORKING_REFERENCE(localState, {
        projectId: 'Foo',
        branchId: 'bar',
        reference: 'foo-bar-ref',
      });

      expect(localState.projects.Foo.branches.bar.workingReference).toBe('foo-bar-ref');
    });

    it('does not fail on non-existent just yet branch', () => {
      expect(localState.projects.Foo.branches.unknown).toBeUndefined();

      mutations.SET_BRANCH_WORKING_REFERENCE(localState, {
        projectId: 'Foo',
        branchId: 'unknown',
        reference: 'fun-fun-ref',
      });

      expect(localState.projects.Foo.branches.unknown).not.toBeUndefined();
      expect(localState.projects.Foo.branches.unknown.workingReference).toBe('fun-fun-ref');
    });
  });
});
