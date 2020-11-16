import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { createStore } from '~/ide/stores';
import ErrorMessage from '~/ide/components/error_message.vue';
import FindFile from '~/vue_shared/components/file_finder/index.vue';
import CommitEditorHeader from '~/ide/components/commit_sidebar/editor_header.vue';
import RepoTabs from '~/ide/components/repo_tabs.vue';
import IdeStatusBar from '~/ide/components/ide_status_bar.vue';
import RightPane from '~/ide/components/panes/right.vue';
import NewModal from '~/ide/components/new_dropdown/modal.vue';

import ide from '~/ide/components/ide.vue';
import { file } from '../helpers';
import { projectData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('WebIDE', () => {
  const emptyProjData = { ...projectData, empty_repo: true, branches: {} };

  let wrapper;

  function createComponent({ projData = emptyProjData, state = {} } = {}) {
    const store = createStore();

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = { ...projData };
    store.state.trees['abcproject/master'] = {
      tree: [],
      loading: false,
    };
    Object.keys(state).forEach(key => {
      store.state[key] = state[key];
    });

    return shallowMount(ide, {
      store,
      localVue,
      stubs: {
        ErrorMessage,
        GlButton,
        GlLoadingIcon,
        CommitEditorHeader,
        RepoTabs,
        IdeStatusBar,
        FindFile,
        RightPane,
        NewModal,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('ide component, empty repo', () => {
    beforeEach(() => {
      wrapper = createComponent({
        projData: {
          empty_repo: true,
        },
      });
    });

    it('renders "New file" button in empty repo', async () => {
      expect(wrapper.find('[title="New file"]').exists()).toBe(true);
    });
  });

  describe('ide component, non-empty repo', () => {
    describe('error message', () => {
      it('does not show error message when it is not set', () => {
        wrapper = createComponent({
          state: {
            errorMessage: null,
          },
        });

        expect(wrapper.find(ErrorMessage).exists()).toBe(false);
      });

      it('shows error message when set', () => {
        wrapper = createComponent({
          state: {
            errorMessage: {
              text: 'error',
            },
          },
        });

        expect(wrapper.find(ErrorMessage).exists()).toBe(true);
      });
    });

    describe('onBeforeUnload', () => {
      it('returns undefined when no staged files or changed files', () => {
        wrapper = createComponent();
        expect(wrapper.vm.onBeforeUnload()).toBe(undefined);
      });

      it('returns warning text when their are changed files', () => {
        wrapper = createComponent({
          state: {
            changedFiles: [file()],
          },
        });

        expect(wrapper.vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
      });

      it('returns warning text when their are staged files', () => {
        wrapper = createComponent({
          state: {
            stagedFiles: [file()],
          },
        });

        expect(wrapper.vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
      });

      it('updates event object', () => {
        const event = {};
        wrapper = createComponent({
          state: {
            stagedFiles: [file()],
          },
        });

        wrapper.vm.onBeforeUnload(event);

        expect(event.returnValue).toBe('Are you sure you want to lose unsaved changes?');
      });
    });

    describe('non-existent branch', () => {
      it('does not render "New file" button for non-existent branch when repo is not empty', () => {
        wrapper = createComponent({
          state: {
            projects: {},
          },
        });

        expect(wrapper.find('[title="New file"]').exists()).toBe(false);
      });
    });

    describe('branch with files', () => {
      beforeEach(() => {
        wrapper = createComponent({
          projData: {
            empty_repo: false,
          },
        });
      });

      it('does not render "New file" button', () => {
        expect(wrapper.find('[title="New file"]').exists()).toBe(false);
      });
    });
  });
});
