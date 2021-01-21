import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { createStore } from '~/ide/stores';
import ErrorMessage from '~/ide/components/error_message.vue';
import Ide from '~/ide/components/ide.vue';
import { file } from '../helpers';
import { projectData } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('WebIDE', () => {
  const emptyProjData = { ...projectData, empty_repo: true, branches: {} };

  let wrapper;

  const createComponent = ({ projData = emptyProjData, state = {} } = {}) => {
    const store = createStore();

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = projData && { ...projData };
    store.state.trees['abcproject/master'] = {
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

  const findAlert = () => wrapper.find(GlAlert);

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
    createComponent({
      projData: {
        userPermissions: {
          pushCode: false,
        },
      },
    });

    expect(findAlert().props()).toMatchObject({
      dismissible: false,
    });
    expect(findAlert().text()).toBe(Ide.MSG_CANNOT_PUSH_CODE);
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
