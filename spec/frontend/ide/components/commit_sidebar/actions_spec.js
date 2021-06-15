import Vue from 'vue';
import { createComponentWithStore } from 'helpers/vue_mount_component_helper';
import { projectData, branches } from 'jest/ide/mock_data';
import commitActions from '~/ide/components/commit_sidebar/actions.vue';
import { createStore } from '~/ide/stores';
import {
  COMMIT_TO_NEW_BRANCH,
  COMMIT_TO_CURRENT_BRANCH,
} from '~/ide/stores/modules/commit/constants';

const ACTION_UPDATE_COMMIT_ACTION = 'commit/updateCommitAction';

const BRANCH_DEFAULT = 'main';
const BRANCH_PROTECTED = 'protected/access';
const BRANCH_PROTECTED_NO_ACCESS = 'protected/no-access';
const BRANCH_REGULAR = 'regular';
const BRANCH_REGULAR_NO_ACCESS = 'regular/no-access';

describe('IDE commit sidebar actions', () => {
  let store;
  let vm;

  const createComponent = ({ hasMR = false, currentBranchId = 'main', emptyRepo = false } = {}) => {
    const Component = Vue.extend(commitActions);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.currentBranchId = currentBranchId;
    vm.$store.state.currentProjectId = 'abcproject';

    const proj = { ...projectData };
    proj.branches[currentBranchId] = branches.find((branch) => branch.name === currentBranchId);
    proj.empty_repo = emptyRepo;

    Vue.set(vm.$store.state.projects, 'abcproject', proj);

    if (hasMR) {
      vm.$store.state.currentMergeRequestId = '1';
      vm.$store.state.projects[store.state.currentProjectId].mergeRequests[
        store.state.currentMergeRequestId
      ] = { foo: 'bar' };
    }

    vm.$mount();

    return vm;
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;
  });

  const findText = () => vm.$el.textContent;
  const findRadios = () => Array.from(vm.$el.querySelectorAll('input[type="radio"]'));

  it('renders 2 groups', () => {
    createComponent();

    expect(findRadios().length).toBe(2);
  });

  it('renders current branch text', () => {
    createComponent();

    expect(findText()).toContain('Commit to main branch');
  });

  it('hides merge request option when project merge requests are disabled', (done) => {
    createComponent({ hasMR: false });

    vm.$nextTick(() => {
      expect(findRadios().length).toBe(2);
      expect(findText()).not.toContain('Create a new branch and merge request');

      done();
    });
  });

  describe('currentBranchText', () => {
    it('escapes current branch', () => {
      const injectedSrc = '<img src="x" />';
      createComponent({ currentBranchId: injectedSrc });

      expect(vm.currentBranchText).not.toContain(injectedSrc);
    });
  });

  describe('updateSelectedCommitAction', () => {
    it('does not return anything if currentBranch does not exist', () => {
      createComponent({ currentBranchId: null });

      expect(vm.$store.dispatch).not.toHaveBeenCalled();
    });

    it('is not called on mount if there is already a selected commitAction', () => {
      store.state.commitAction = '1';
      createComponent({ currentBranchId: null });

      expect(vm.$store.dispatch).not.toHaveBeenCalled();
    });

    it('calls again after staged changes', (done) => {
      createComponent({ currentBranchId: null });

      vm.$store.state.currentBranchId = 'main';
      vm.$store.state.changedFiles.push({});
      vm.$store.state.stagedFiles.push({});

      vm.$nextTick()
        .then(() => {
          expect(vm.$store.dispatch).toHaveBeenCalledWith(
            ACTION_UPDATE_COMMIT_ACTION,
            expect.anything(),
          );
        })
        .then(done)
        .catch(done.fail);
    });

    it.each`
      input                                                            | expectedOption
      ${{ currentBranchId: BRANCH_DEFAULT }}                           | ${COMMIT_TO_NEW_BRANCH}
      ${{ currentBranchId: BRANCH_DEFAULT, emptyRepo: true }}          | ${COMMIT_TO_CURRENT_BRANCH}
      ${{ currentBranchId: BRANCH_PROTECTED, hasMR: true }}            | ${COMMIT_TO_CURRENT_BRANCH}
      ${{ currentBranchId: BRANCH_PROTECTED, hasMR: false }}           | ${COMMIT_TO_CURRENT_BRANCH}
      ${{ currentBranchId: BRANCH_PROTECTED_NO_ACCESS, hasMR: true }}  | ${COMMIT_TO_NEW_BRANCH}
      ${{ currentBranchId: BRANCH_PROTECTED_NO_ACCESS, hasMR: false }} | ${COMMIT_TO_NEW_BRANCH}
      ${{ currentBranchId: BRANCH_REGULAR, hasMR: true }}              | ${COMMIT_TO_CURRENT_BRANCH}
      ${{ currentBranchId: BRANCH_REGULAR, hasMR: false }}             | ${COMMIT_TO_CURRENT_BRANCH}
      ${{ currentBranchId: BRANCH_REGULAR_NO_ACCESS, hasMR: true }}    | ${COMMIT_TO_NEW_BRANCH}
      ${{ currentBranchId: BRANCH_REGULAR_NO_ACCESS, hasMR: false }}   | ${COMMIT_TO_NEW_BRANCH}
    `(
      'with $input, it dispatches update commit action with $expectedOption',
      ({ input, expectedOption }) => {
        createComponent(input);

        expect(vm.$store.dispatch.mock.calls).toEqual([
          [ACTION_UPDATE_COMMIT_ACTION, expectedOption],
        ]);
      },
    );
  });

  describe('when empty project', () => {
    beforeEach(() => {
      createComponent({ emptyRepo: true });
    });

    it('only renders commit to current branch', () => {
      expect(findRadios().length).toBe(1);
      expect(findText()).toContain('Commit to main branch');
    });
  });
});
