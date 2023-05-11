import { GlButton, GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';

import ActionsButton from '~/vue_shared/components/actions_button.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WebIdeLink, {
  i18n,
  PREFERRED_EDITOR_RESET_KEY,
  PREFERRED_EDITOR_KEY,
} from '~/vue_shared/components/web_ide_link.vue';
import ConfirmForkModal from '~/vue_shared/components/confirm_fork_modal.vue';
import { KEY_WEB_IDE } from '~/vue_shared/components/constants';

import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

const TEST_EDIT_URL = '/gitlab-test/test/-/edit/main/';
const TEST_WEB_IDE_URL = '/-/ide/project/gitlab-test/test/edit/main/-/';
const TEST_GITPOD_URL = 'https://gitpod.test/';
const TEST_PIPELINE_EDITOR_URL = '/-/ci/editor?branch_name="main"';
const TEST_USER_PREFERENCES_GITPOD_PATH = '/-/profile/preferences#user_gitpod_enabled';
const TEST_USER_PROFILE_ENABLE_GITPOD_PATH = '/-/profile?user%5Bgitpod_enabled%5D=true';
const forkPath = '/some/fork/path';

const ACTION_EDIT = {
  href: TEST_EDIT_URL,
  key: 'edit',
  text: 'Edit',
  secondaryText: 'Edit this file only.',
  tooltip: '',
  attrs: {
    'data-qa-selector': 'edit_button',
    'data-track-action': 'click_consolidated_edit',
    'data-track-label': 'edit',
  },
};
const ACTION_EDIT_CONFIRM_FORK = {
  ...ACTION_EDIT,
  href: '#modal-confirm-fork-edit',
  handle: expect.any(Function),
};
const ACTION_WEB_IDE = {
  href: TEST_WEB_IDE_URL,
  key: 'webide',
  secondaryText: i18n.webIdeText,
  tooltip: i18n.webIdeTooltip,
  text: 'Web IDE',
  attrs: {
    'data-qa-selector': 'web_ide_button',
    'data-track-action': 'click_consolidated_edit_ide',
    'data-track-label': 'web_ide',
  },
  handle: expect.any(Function),
};
const ACTION_WEB_IDE_CONFIRM_FORK = {
  ...ACTION_WEB_IDE,
  href: '#modal-confirm-fork-webide',
  handle: expect.any(Function),
};
const ACTION_WEB_IDE_EDIT_FORK = { ...ACTION_WEB_IDE, text: 'Edit fork in Web IDE' };
const ACTION_GITPOD = {
  href: TEST_GITPOD_URL,
  key: 'gitpod',
  secondaryText: 'Launch a ready-to-code development environment for your project.',
  tooltip: 'Launch a ready-to-code development environment for your project.',
  text: 'Gitpod',
  attrs: {
    'data-qa-selector': 'gitpod_button',
  },
};
const ACTION_GITPOD_ENABLE = {
  ...ACTION_GITPOD,
  href: undefined,
  handle: expect.any(Function),
};
const ACTION_PIPELINE_EDITOR = {
  href: TEST_PIPELINE_EDITOR_URL,
  key: 'pipeline_editor',
  secondaryText: 'Edit, lint, and visualize your pipeline.',
  tooltip: 'Edit, lint, and visualize your pipeline.',
  text: 'Edit in pipeline editor',
  attrs: {
    'data-qa-selector': 'pipeline_editor_button',
  },
};

describe('Web IDE link component', () => {
  useLocalStorageSpy();

  let wrapper;

  function createComponent(props, { mountFn = shallowMountExtended, glFeatures = {} } = {}) {
    wrapper = mountFn(WebIdeLink, {
      propsData: {
        editUrl: TEST_EDIT_URL,
        webIdeUrl: TEST_WEB_IDE_URL,
        gitpodUrl: TEST_GITPOD_URL,
        pipelineEditorUrl: TEST_PIPELINE_EDITOR_URL,
        forkPath,
        ...props,
      },
      provide: {
        glFeatures,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <slot></slot>
              <slot name="modal-footer"></slot>
            </div>`,
        }),
      },
    });
  }

  beforeEach(() => {
    localStorage.setItem(PREFERRED_EDITOR_RESET_KEY, 'true');
  });

  const findActionsButton = () => wrapper.findComponent(ActionsButton);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForkConfirmModal = () => wrapper.findComponent(ConfirmForkModal);

  it.each([
    {
      props: {},
      expectedActions: [ACTION_WEB_IDE, ACTION_EDIT],
    },
    {
      props: { showPipelineEditorButton: true },
      expectedActions: [ACTION_PIPELINE_EDITOR, ACTION_WEB_IDE, ACTION_EDIT],
    },
    {
      props: { webIdeText: 'Test Web IDE' },
      expectedActions: [{ ...ACTION_WEB_IDE_EDIT_FORK, text: 'Test Web IDE' }, ACTION_EDIT],
    },
    {
      props: { isFork: true },
      expectedActions: [ACTION_WEB_IDE_EDIT_FORK, ACTION_EDIT],
    },
    {
      props: { needsToFork: true },
      expectedActions: [ACTION_WEB_IDE_CONFIRM_FORK, ACTION_EDIT_CONFIRM_FORK],
    },
    {
      props: {
        showWebIdeButton: false,
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: true,
      },
      expectedActions: [ACTION_EDIT, ACTION_GITPOD],
    },
    {
      props: {
        showWebIdeButton: false,
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        gitpodEnabled: true,
      },
      expectedActions: [ACTION_EDIT],
    },
    {
      props: {
        showWebIdeButton: false,
        showGitpodButton: true,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: true,
      },
      expectedActions: [ACTION_EDIT],
    },
    {
      props: {
        showWebIdeButton: false,
        showGitpodButton: true,
        gitpodEnabled: true,
      },
      expectedActions: [ACTION_EDIT],
    },
    {
      props: {
        showWebIdeButton: false,
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: false,
      },
      expectedActions: [ACTION_EDIT, ACTION_GITPOD_ENABLE],
    },
    {
      props: {
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: false,
      },
      expectedActions: [ACTION_WEB_IDE, ACTION_EDIT, ACTION_GITPOD_ENABLE],
    },
    {
      props: {
        showEditButton: false,
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodText: 'Test Gitpod',
      },
      expectedActions: [ACTION_WEB_IDE, { ...ACTION_GITPOD_ENABLE, text: 'Test Gitpod' }],
    },
    {
      props: { showEditButton: false },
      expectedActions: [ACTION_WEB_IDE],
    },
  ])('renders actions with appropriately for given props', ({ props, expectedActions }) => {
    createComponent(props);

    expect(findActionsButton().props('actions')).toEqual(expectedActions);
  });

  describe('when pipeline editor action is available', () => {
    beforeEach(() => {
      createComponent({
        showEditButton: false,
        showWebIdeButton: true,
        showGitpodButton: true,
        showPipelineEditorButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: true,
      });
    });

    it('selected Pipeline Editor by default', () => {
      expect(findActionsButton().props()).toMatchObject({
        actions: [ACTION_PIPELINE_EDITOR, ACTION_WEB_IDE, ACTION_GITPOD],
        selectedKey: ACTION_PIPELINE_EDITOR.key,
      });
    });

    it('when web ide button is clicked it opens in a new tab', async () => {
      findActionsButton().props('actions')[1].handle({
        preventDefault: jest.fn(),
      });
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(ACTION_WEB_IDE.href, true);
    });
  });

  describe('with multiple actions', () => {
    beforeEach(() => {
      createComponent({
        showEditButton: false,
        showWebIdeButton: true,
        showGitpodButton: true,
        showPipelineEditorButton: false,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: true,
      });
    });

    it('selected Web IDE by default', () => {
      expect(findActionsButton().props()).toMatchObject({
        actions: [ACTION_WEB_IDE, ACTION_GITPOD],
        selectedKey: ACTION_WEB_IDE.key,
      });
    });

    it('should set selection with local storage value', async () => {
      expect(findActionsButton().props('selectedKey')).toBe(ACTION_WEB_IDE.key);

      findLocalStorageSync().vm.$emit('input', ACTION_GITPOD.key);

      await nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
    });

    it('should update local storage when selection changes', async () => {
      expect(findLocalStorageSync().props()).toMatchObject({
        asString: true,
        value: ACTION_WEB_IDE.key,
      });

      findActionsButton().vm.$emit('select', ACTION_GITPOD.key);

      await nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
      expect(findLocalStorageSync().props('value')).toBe(ACTION_GITPOD.key);
    });
  });

  describe('edit actions', () => {
    const testActions = [
      {
        props: {
          showWebIdeButton: true,
          showEditButton: false,
          showPipelineEditorButton: false,
          forkPath,
          forkModalId: 'edit-modal',
        },
        expectedEventPayload: 'ide',
      },
      {
        props: {
          showWebIdeButton: false,
          showEditButton: true,
          showPipelineEditorButton: false,
          forkPath,
          forkModalId: 'webide-modal',
        },
        expectedEventPayload: 'simple',
      },
    ];

    it.each(testActions)(
      'emits the correct event when an action handler is called',
      ({ props, expectedEventPayload }) => {
        createComponent({ ...props, needsToFork: true, disableForkModal: true });

        findActionsButton().props('actions')[0].handle();

        expect(wrapper.emitted('edit')).toEqual([[expectedEventPayload]]);
      },
    );

    it.each(testActions)('renders the fork confirmation modal', ({ props }) => {
      createComponent({ ...props, needsToFork: true });

      expect(findForkConfirmModal().exists()).toBe(true);
      expect(findForkConfirmModal().props()).toEqual({
        visible: false,
        forkPath,
        modalId: props.forkModalId,
      });
    });

    it.each(testActions)('opens the modal when the button is clicked', async ({ props }) => {
      createComponent({ ...props, needsToFork: true }, { mountFn: mountExtended });

      await findActionsButton().findComponent(GlButton).trigger('click');

      expect(findForkConfirmModal().props()).toEqual({
        visible: true,
        forkPath,
        modalId: props.forkModalId,
      });
    });
  });

  describe('when Gitpod is not enabled', () => {
    it('renders closed modal to enable Gitpod', () => {
      createComponent({
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: false,
      });

      const modal = findModal();

      expect(modal.exists()).toBe(true);
      expect(modal.props()).toMatchObject({
        visible: false,
        modalId: 'enable-gitpod-modal',
        size: 'sm',
        title: WebIdeLink.i18n.modal.title,
        actionCancel: {
          text: WebIdeLink.i18n.modal.actionCancelText,
        },
        actionPrimary: {
          text: WebIdeLink.i18n.modal.actionPrimaryText,
          attributes: {
            variant: 'confirm',
            category: 'primary',
            href: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
            'data-method': 'put',
          },
        },
      });
    });

    it('opens modal when `Gitpod` action is clicked', async () => {
      const gitpodText = 'Open in Gitpod';

      createComponent(
        {
          showGitpodButton: true,
          userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
          userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
          gitpodEnabled: false,
          gitpodText,
        },
        { mountFn: mountExtended },
      );

      findLocalStorageSync().vm.$emit('input', ACTION_GITPOD.key);

      await nextTick();
      await wrapper.findByRole('button', { name: gitpodText }).trigger('click');

      expect(findModal().props('visible')).toBe(true);
    });
  });

  describe('when Gitpod is enabled', () => {
    it('does not render modal', () => {
      createComponent({
        showGitpodButton: true,
        userPreferencesGitpodPath: TEST_USER_PREFERENCES_GITPOD_PATH,
        userProfileEnableGitpodPath: TEST_USER_PROFILE_ENABLE_GITPOD_PATH,
        gitpodEnabled: true,
      });

      expect(findModal().exists()).toBe(false);
    });
  });

  describe('when vscode_web_ide feature flag is enabled', () => {
    describe('when is not showing edit button', () => {
      describe(`when ${PREFERRED_EDITOR_RESET_KEY} is unset`, () => {
        beforeEach(() => {
          localStorage.setItem.mockReset();
          localStorage.getItem.mockReturnValueOnce(null);
          createComponent({ showEditButton: false }, { glFeatures: { vscodeWebIde: true } });
        });

        it(`sets ${PREFERRED_EDITOR_KEY} local storage key to ${KEY_WEB_IDE}`, () => {
          expect(localStorage.getItem).toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY);
          expect(localStorage.setItem).toHaveBeenCalledWith(PREFERRED_EDITOR_KEY, KEY_WEB_IDE);
        });

        it(`sets ${PREFERRED_EDITOR_RESET_KEY} local storage key to true`, () => {
          expect(localStorage.setItem).toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY, true);
        });

        it(`selects ${KEY_WEB_IDE} as the preferred editor`, () => {
          expect(findActionsButton().props().selectedKey).toBe(KEY_WEB_IDE);
        });
      });

      describe(`when ${PREFERRED_EDITOR_RESET_KEY} is set to true`, () => {
        beforeEach(() => {
          localStorage.setItem.mockReset();
          localStorage.getItem.mockReturnValueOnce('true');
          createComponent({ showEditButton: false }, { glFeatures: { vscodeWebIde: true } });
        });

        it(`does not update the persisted preferred editor`, () => {
          expect(localStorage.getItem).toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY);
          expect(localStorage.setItem).not.toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY);
        });
      });
    });

    describe('when is showing the edit button', () => {
      it(`does not try to reset the ${PREFERRED_EDITOR_KEY}`, () => {
        createComponent({ showEditButton: true }, { glFeatures: { vscodeWebIde: true } });

        expect(localStorage.getItem).not.toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY);
      });
    });
  });

  describe('when vscode_web_ide feature flag is disabled', () => {
    it(`does not try to reset the ${PREFERRED_EDITOR_KEY}`, () => {
      createComponent({}, { glFeatures: { vscodeWebIde: false } });

      expect(localStorage.getItem).not.toHaveBeenCalledWith(PREFERRED_EDITOR_RESET_KEY);
    });
  });
});
