import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { projectData } from 'jest/ide/mock_data';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { createStore } from '~/ide/stores';
import { COMMIT_TO_NEW_BRANCH } from '~/ide/stores/modules/commit/constants';
import CommitForm from '~/ide/components/commit_sidebar/form.vue';
import CommitMessageField from '~/ide/components/commit_sidebar/message_field.vue';
import { leftSidebarViews } from '~/ide/constants';
import {
  createCodeownersCommitError,
  createUnexpectedCommitError,
  createBranchChangedCommitError,
  branchAlreadyExistsCommitError,
} from '~/ide/lib/errors';

describe('IDE commit form', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = shallowMount(CommitForm, {
      store,
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  const setLastCommitMessage = (msg) => {
    store.state.lastCommitMsg = msg;
  };
  const goToCommitView = () => {
    store.state.currentActivityView = leftSidebarViews.commit.name;
  };
  const goToEditView = () => {
    store.state.currentActivityView = leftSidebarViews.edit.name;
  };
  const findBeginCommitButton = () => wrapper.find('[data-testid="begin-commit-button"]');
  const findCommitButton = () => wrapper.find('[data-testid="commit-button"]');
  const findForm = () => wrapper.find('form');
  const findCommitMessageInput = () => wrapper.find(CommitMessageField);
  const setCommitMessageInput = (val) => findCommitMessageInput().vm.$emit('input', val);
  const findDiscardDraftButton = () => wrapper.find('[data-testid="discard-draft"]');

  beforeEach(() => {
    store = createStore();
    store.state.stagedFiles.push('test');
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    Vue.set(store.state.projects, 'abcproject', {
      ...projectData,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    desc                           | stagedFiles | disabled
    ${'when there are changes'}    | ${['test']} | ${false}
    ${'when there are no changes'} | ${[]}       | ${true}
  `('$desc', ({ stagedFiles, disabled }) => {
    beforeEach(async () => {
      store.state.stagedFiles = stagedFiles;

      createComponent();
    });

    it(`begin button disabled=${disabled}`, async () => {
      expect(findBeginCommitButton().props('disabled')).toBe(disabled);
    });
  });

  describe('on edit tab', () => {
    beforeEach(async () => {
      // Test that we react to switching to compact view.
      goToCommitView();

      createComponent();

      goToEditView();

      await wrapper.vm.$nextTick();
    });

    it('renders commit button in compact mode', () => {
      expect(findBeginCommitButton().exists()).toBe(true);
      expect(findBeginCommitButton().text()).toBe('Commit…');
    });

    it('does not render form', () => {
      expect(findForm().exists()).toBe(false);
    });

    it('renders overview text', () => {
      expect(wrapper.find('p').text()).toBe('1 changed file');
    });

    it('when begin commit button is clicked, shows form', async () => {
      findBeginCommitButton().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(findForm().exists()).toBe(true);
    });

    it('when begin commit button is clicked, sets activity view', async () => {
      findBeginCommitButton().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(store.state.currentActivityView).toBe(leftSidebarViews.commit.name);
    });

    it('collapses if lastCommitMsg is set to empty and current view is not commit view', async () => {
      // Test that it expands when lastCommitMsg is set
      setLastCommitMessage('test');
      goToEditView();

      await wrapper.vm.$nextTick();

      expect(findForm().exists()).toBe(true);

      // Now test that it collapses when lastCommitMsg is cleared
      setLastCommitMessage('');

      await wrapper.vm.$nextTick();

      expect(findForm().exists()).toBe(false);
    });
  });

  describe('on commit tab when window height is less than MAX_WINDOW_HEIGHT', () => {
    let oldHeight;

    beforeEach(async () => {
      oldHeight = window.innerHeight;
      window.innerHeight = 700;

      createComponent();

      goToCommitView();

      await wrapper.vm.$nextTick();
    });

    afterEach(() => {
      window.innerHeight = oldHeight;
    });

    it('stays collapsed if changes are added or removed', async () => {
      expect(findForm().exists()).toBe(false);

      store.state.stagedFiles = [];
      await wrapper.vm.$nextTick();

      expect(findForm().exists()).toBe(false);

      store.state.stagedFiles.push('test');
      await wrapper.vm.$nextTick();

      expect(findForm().exists()).toBe(false);
    });
  });

  describe('on commit tab', () => {
    beforeEach(async () => {
      // Test that the component reacts to switching to full view
      goToEditView();

      createComponent();

      goToCommitView();

      await wrapper.vm.$nextTick();
    });

    it('shows form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('hides begin commit button', () => {
      expect(findBeginCommitButton().exists()).toBe(false);
    });

    describe('when no changed files', () => {
      beforeEach(async () => {
        store.state.stagedFiles = [];
        await wrapper.vm.$nextTick();
      });

      it('hides form', () => {
        expect(findForm().exists()).toBe(false);
      });

      it('expands again when staged files are added', async () => {
        store.state.stagedFiles.push('test');
        await wrapper.vm.$nextTick();

        expect(findForm().exists()).toBe(true);
      });
    });

    it('updates commitMessage in store on input', async () => {
      setCommitMessageInput('testing commit message');

      await wrapper.vm.$nextTick();

      expect(store.state.commit.commitMessage).toBe('testing commit message');
    });

    describe('discard draft button', () => {
      it('hidden when commitMessage is empty', () => {
        expect(findDiscardDraftButton().exists()).toBe(false);
      });

      it('resets commitMessage when clicking discard button', async () => {
        setCommitMessageInput('testing commit message');

        await wrapper.vm.$nextTick();

        expect(findCommitMessageInput().props('text')).toBe('testing commit message');

        // Test that commitMessage is cleared on click
        findDiscardDraftButton().vm.$emit('click');

        await wrapper.vm.$nextTick();

        expect(findCommitMessageInput().props('text')).toBe('');
      });
    });

    describe('when submitting', () => {
      beforeEach(async () => {
        goToEditView();

        createComponent();

        goToCommitView();

        await wrapper.vm.$nextTick();

        setCommitMessageInput('testing commit message');

        await wrapper.vm.$nextTick();

        jest.spyOn(store, 'dispatch').mockResolvedValue();
      });

      it('calls commitChanges', () => {
        findCommitButton().vm.$emit('click');

        expect(store.dispatch).toHaveBeenCalledWith('commit/commitChanges', undefined);
      });

      it.each`
        createError                                          | props
        ${() => createCodeownersCommitError('test message')} | ${{ actionPrimary: { text: 'Create new branch' } }}
        ${createUnexpectedCommitError}                       | ${{ actionPrimary: null }}
      `('opens error modal if commitError with $error', async ({ createError, props }) => {
        const modal = wrapper.find(GlModal);
        modal.vm.show = jest.fn();

        const error = createError();
        store.state.commit.commitError = error;

        await wrapper.vm.$nextTick();

        expect(modal.vm.show).toHaveBeenCalled();
        expect(modal.props()).toMatchObject({
          actionCancel: { text: 'Cancel' },
          ...props,
        });
        // Because of the legacy 'mountComponent' approach here, the only way to
        // test the text of the modal is by viewing the content of the modal added to the document.
        expect(modal.html()).toContain(error.messageHTML);
      });
    });

    describe('with error modal with primary', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockResolvedValue();
      });

      const commitActions = [
        ['commit/updateCommitAction', COMMIT_TO_NEW_BRANCH],
        ['commit/commitChanges'],
      ];

      it.each`
        commitError                       | expectedActions
        ${createCodeownersCommitError}    | ${commitActions}
        ${createBranchChangedCommitError} | ${commitActions}
        ${branchAlreadyExistsCommitError} | ${[['commit/addSuffixToBranchName'], ...commitActions]}
      `(
        'updates commit action and commits for error: $commitError',
        async ({ commitError, expectedActions }) => {
          store.state.commit.commitError = commitError('test message');

          await wrapper.vm.$nextTick();

          wrapper.find(GlModal).vm.$emit('ok');

          await waitForPromises();

          expect(store.dispatch.mock.calls).toEqual(expectedActions);
        },
      );
    });
  });
});
