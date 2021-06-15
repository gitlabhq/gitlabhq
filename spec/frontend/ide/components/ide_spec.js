import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import CannotPushCodeAlert from '~/ide/components/cannot_push_code_alert.vue';
import ErrorMessage from '~/ide/components/error_message.vue';
import Ide from '~/ide/components/ide.vue';
import { MSG_CANNOT_PUSH_CODE_GO_TO_FORK, MSG_GO_TO_FORK } from '~/ide/messages';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_FORK_IDE_PATH = '/test/ide/path';

describe('WebIDE', () => {
  const emptyProjData = { ...projectData, empty_repo: true, branches: {} };

  let store;
  let wrapper;

  const createComponent = ({ projData = emptyProjData, state = {} } = {}) => {
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'main';
    store.state.projects.abcproject = projData && { ...projData };
    store.state.trees['abcproject/main'] = {
      tree: [],
      loading: false,
    };
    Object.keys(state).forEach((key) => {
      store.state[key] = state[key];
    });

    wrapper = shallowMount(Ide, {
      store,
      localVue,
    });
  };

  const findAlert = () => wrapper.findComponent(CannotPushCodeAlert);

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('ide component, empty repo', () => {
    beforeEach(() => {
      createComponent({
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
      it.each`
        errorMessage         | exists
        ${null}              | ${false}
        ${{ text: 'error' }} | ${true}
      `(
        'should error message exists=$exists when errorMessage=$errorMessage',
        async ({ errorMessage, exists }) => {
          createComponent({
            state: {
              errorMessage,
            },
          });

          await waitForPromises();

          expect(wrapper.find(ErrorMessage).exists()).toBe(exists);
        },
      );
    });

    describe('onBeforeUnload', () => {
      it('returns undefined when no staged files or changed files', () => {
        createComponent();
        expect(wrapper.vm.onBeforeUnload()).toBe(undefined);
      });

      it('returns warning text when their are changed files', () => {
        createComponent({
          state: {
            changedFiles: [file()],
          },
        });

        expect(wrapper.vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
      });

      it('returns warning text when their are staged files', () => {
        createComponent({
          state: {
            stagedFiles: [file()],
          },
        });

        expect(wrapper.vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
      });

      it('updates event object', () => {
        const event = {};
        createComponent({
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
        createComponent({
          state: {
            projects: {},
          },
        });

        expect(wrapper.find('[title="New file"]').exists()).toBe(false);
      });
    });

    describe('branch with files', () => {
      beforeEach(() => {
        createComponent({
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

  it('when user cannot push code, shows alert', () => {
    store.state.links = {
      forkInfo: {
        ide_path: TEST_FORK_IDE_PATH,
      },
    };

    createComponent({
      projData: {
        userPermissions: {
          pushCode: false,
        },
      },
    });

    expect(findAlert().props()).toMatchObject({
      message: MSG_CANNOT_PUSH_CODE_GO_TO_FORK,
      action: {
        href: TEST_FORK_IDE_PATH,
        text: MSG_GO_TO_FORK,
      },
    });
  });

  it.each`
    desc                           | projData
    ${'when user can push code'}   | ${{ userPermissions: { pushCode: true } }}
    ${'when project is not ready'} | ${null}
  `('$desc, no alert is shown', ({ projData }) => {
    createComponent({
      projData,
    });

    expect(findAlert().exists()).toBe(false);
  });
});
