import { shallowMount } from '@vue/test-utils';
import { GlBroadcastMessage, GlLink, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { stubPerformanceWebAPI } from 'helpers/performance';
import CannotPushCodeAlert from '~/ide/components/cannot_push_code_alert.vue';
import ErrorMessage from '~/ide/components/error_message.vue';
import Ide from '~/ide/components/ide.vue';
import eventHub from '~/ide/eventhub';
import { MSG_CANNOT_PUSH_CODE_GO_TO_FORK, MSG_GO_TO_FORK } from '~/ide/messages';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';
import { projectData } from '../mock_data';

Vue.use(Vuex);

const TEST_FORK_IDE_PATH = '/test/ide/path';
const MSG_ARE_YOU_SURE = 'Are you sure you want to lose unsaved changes?';

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
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(CannotPushCodeAlert);

  const findBroadcastMessage = () => wrapper.findComponent(GlBroadcastMessage);
  const callOnBeforeUnload = (e = {}) => window.onbeforeunload(e);

  beforeAll(() => {
    // HACK: Workaround readonly property in Jest
    Object.defineProperty(window, 'onbeforeunload', {
      writable: true,
    });
  });

  beforeEach(() => {
    stubPerformanceWebAPI();

    store = createStore();
  });

  afterEach(() => {
    window.onbeforeunload = null;
  });

  describe('removal announcement', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays removal announcement', () => {
      expect(findBroadcastMessage().text()).toMatch(
        /The legacy Vue-based GitLab Web IDE will be removed in GitLab 18.0/,
      );
      expect(findBroadcastMessage().text()).toMatch(
        /To prepare for this removal, see deprecations and removals./,
      );
    });

    it('displays a banner with a link to the deprecation announcement', () => {
      const glLink = findBroadcastMessage().findComponent(GlLink);
      expect(glLink.attributes('href')).toBe(
        '/help/update/deprecations.md#legacy-web-ide-is-deprecated',
      );
    });

    it('does not allow dismissing the announcement', () => {
      expect(findBroadcastMessage().props()).toMatchObject({
        dismissible: false,
        iconName: 'warning',
        theme: 'red',
      });
    });
  });

  describe('ide component, empty repo', () => {
    beforeEach(() => {
      createComponent({
        projData: {
          empty_repo: true,
        },
      });
    });

    it('renders "New file" button in empty repo', () => {
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

          expect(wrapper.findComponent(ErrorMessage).exists()).toBe(exists);
        },
      );
    });

    describe('onBeforeUnload', () => {
      it('returns undefined when no staged files or changed files', () => {
        createComponent();

        expect(callOnBeforeUnload()).toBe(undefined);
      });

      it('returns warning text when their are changed files', () => {
        createComponent({
          state: {
            changedFiles: [file()],
          },
        });

        const e = {};

        expect(callOnBeforeUnload(e)).toBe(MSG_ARE_YOU_SURE);
        expect(e.returnValue).toBe(MSG_ARE_YOU_SURE);
      });

      it('returns warning text when their are staged files', () => {
        createComponent({
          state: {
            stagedFiles: [file()],
          },
        });

        const e = {};

        expect(callOnBeforeUnload(e)).toBe(MSG_ARE_YOU_SURE);
        expect(e.returnValue).toBe(MSG_ARE_YOU_SURE);
      });

      it('returns undefined once after "skip-beforeunload" was emitted', () => {
        createComponent({
          state: {
            stagedFiles: [file()],
          },
        });

        eventHub.$emit('skip-beforeunload');
        const e = {};

        expect(callOnBeforeUnload()).toBe(undefined);
        expect(e.returnValue).toBe(undefined);

        expect(callOnBeforeUnload(e)).toBe(MSG_ARE_YOU_SURE);
        expect(e.returnValue).toBe(MSG_ARE_YOU_SURE);
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

  it('when user cannot push code, shows an alert', () => {
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
