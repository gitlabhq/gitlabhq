import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { projectData, branches } from 'jest/ide/mock_data';
import CommitActions from '~/ide/components/commit_sidebar/actions.vue';
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
  let wrapper;

  const createComponent = ({ hasMR = false, currentBranchId = 'main', emptyRepo = false } = {}) => {
    store.state.currentBranchId = currentBranchId;
    store.state.currentProjectId = 'abcproject';

    const proj = { ...projectData };
    proj.branches[currentBranchId] = branches.find((branch) => branch.name === currentBranchId);
    proj.empty_repo = emptyRepo;

    store.state.projects = {
      ...store.state.projects,
      abcproject: proj,
    };

    if (hasMR) {
      store.state.currentMergeRequestId = '1';
      store.state.projects[store.state.currentProjectId].mergeRequests[
        store.state.currentMergeRequestId
      ] = { foo: 'bar' };
    }

    wrapper = mount(CommitActions, { store });
    return wrapper;
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  const findText = () => wrapper.text();
  const findRadios = () => wrapper.findAll('input[type="radio"]');

  it('renders 2 groups', () => {
    createComponent();

    expect(findRadios()).toHaveLength(2);
  });

  it('renders current branch text', () => {
    createComponent();

    expect(findText()).toContain('Commit to main branch');
  });

  it('hides merge request option when project merge requests are disabled', async () => {
    createComponent({ hasMR: false });

    await nextTick();
    expect(findRadios().length).toBe(2);
    expect(findText()).not.toContain('Create a new branch and merge request');
  });

  it('escapes current branch name', () => {
    const injectedSrc = '<img src="x" />';
    const escapedSrc = '&lt;img src=&quot;x&quot; /&gt';
    createComponent({ currentBranchId: injectedSrc });

    expect(wrapper.text()).not.toContain(injectedSrc);
    expect(wrapper.text).not.toContain(escapedSrc);
  });

  describe('updateSelectedCommitAction', () => {
    it('does not return anything if currentBranch does not exist', () => {
      createComponent({ currentBranchId: null });

      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('is not called on mount if there is already a selected commitAction', () => {
      store.state.commitAction = '1';
      createComponent({ currentBranchId: null });

      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('calls again after staged changes', async () => {
      createComponent({ currentBranchId: null });

      store.state.currentBranchId = 'main';
      store.state.changedFiles.push({});
      store.state.stagedFiles.push({});

      await nextTick();
      expect(store.dispatch).toHaveBeenCalledWith(ACTION_UPDATE_COMMIT_ACTION, expect.anything());
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

        expect(store.dispatch.mock.calls).toEqual([[ACTION_UPDATE_COMMIT_ACTION, expectedOption]]);
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
