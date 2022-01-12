import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';

import ActionsButton from '~/vue_shared/components/actions_button.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

const TEST_EDIT_URL = '/gitlab-test/test/-/edit/main/';
const TEST_WEB_IDE_URL = '/-/ide/project/gitlab-test/test/edit/main/-/';
const TEST_GITPOD_URL = 'https://gitpod.test/';
const TEST_USER_PREFERENCES_GITPOD_PATH = '/-/profile/preferences#user_gitpod_enabled';
const TEST_USER_PROFILE_ENABLE_GITPOD_PATH = '/-/profile?user%5Bgitpod_enabled%5D=true';

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
  secondaryText: 'Quickly and easily edit multiple files in your project.',
  tooltip: '',
  text: 'Web IDE',
  attrs: {
    'data-qa-selector': 'web_ide_button',
    'data-track-action': 'click_consolidated_edit_ide',
    'data-track-label': 'web_ide',
  },
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

describe('Web IDE link component', () => {
  let wrapper;

  function createComponent(props, mountFn = shallowMountExtended) {
    wrapper = mountFn(WebIdeLink, {
      propsData: {
        editUrl: TEST_EDIT_URL,
        webIdeUrl: TEST_WEB_IDE_URL,
        gitpodUrl: TEST_GITPOD_URL,
        ...props,
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findActionsButton = () => wrapper.find(ActionsButton);
  const findLocalStorageSync = () => wrapper.find(LocalStorageSync);
  const findModal = () => wrapper.findComponent(GlModal);

  it.each([
    {
      props: {},
      expectedActions: [ACTION_WEB_IDE, ACTION_EDIT],
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

  describe('with multiple actions', () => {
    beforeEach(() => {
      createComponent({
        showEditButton: false,
        showWebIdeButton: true,
        showGitpodButton: true,
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

      await wrapper.vm.$nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
    });

    it('should update local storage when selection changes', async () => {
      expect(findLocalStorageSync().props('value')).toBe(ACTION_WEB_IDE.key);

      findActionsButton().vm.$emit('select', ACTION_GITPOD.key);

      await wrapper.vm.$nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
      expect(findLocalStorageSync().props('value')).toBe(ACTION_GITPOD.key);
    });
  });

  describe('edit actions', () => {
    it.each([
      {
        props: { showWebIdeButton: true, showEditButton: false },
        expectedEventPayload: 'ide',
      },
      {
        props: { showWebIdeButton: false, showEditButton: true },
        expectedEventPayload: 'simple',
      },
    ])(
      'emits the correct event when an action handler is called',
      async ({ props, expectedEventPayload }) => {
        createComponent({ ...props, needsToFork: true });

        findActionsButton().props('actions')[0].handle();

        expect(wrapper.emitted('edit')).toEqual([[expectedEventPayload]]);
      },
    );
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
        mountExtended,
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
});
