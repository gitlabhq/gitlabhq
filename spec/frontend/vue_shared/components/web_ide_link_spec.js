import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';

import ActionsButton from '~/vue_shared/components/actions_button.vue';
import WebIdeLink, { i18n } from '~/vue_shared/components/web_ide_link.vue';
import ConfirmForkModal from '~/vue_shared/components/confirm_fork_modal.vue';

import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';

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
  text: 'Edit single file',
  secondaryText: 'Edit this file only.',
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
  key: 'webide',
  secondaryText: i18n.webIdeText,
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
  handle: expect.any(Function),
};
const ACTION_WEB_IDE_EDIT_FORK = { ...ACTION_WEB_IDE, text: 'Edit fork in Web IDE' };
const ACTION_GITPOD = {
  href: TEST_GITPOD_URL,
  key: 'gitpod',
  secondaryText: 'Launch a ready-to-code development environment for your project.',
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
  text: 'Edit in pipeline editor',
  attrs: {
    'data-qa-selector': 'pipeline_editor_button',
  },
};

describe('vue_shared/components/web_ide_link', () => {
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

  const findActionsButton = () => wrapper.findComponent(ActionsButton);
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

    it('displays Pipeline Editor as the first action', () => {
      expect(findActionsButton().props()).toMatchObject({
        actions: [ACTION_PIPELINE_EDITOR, ACTION_WEB_IDE, ACTION_GITPOD],
      });
    });

    it('when web ide button is clicked it opens in a new tab', async () => {
      findActionsButton().props('actions')[1].handle();
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(TEST_WEB_IDE_URL, true);
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

      wrapper.findComponent(ActionsButton).props().actions[0].handle();

      await nextTick();
      await wrapper.findByRole('button', { name: /Web IDE|Edit/im }).trigger('click');

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

      await nextTick();
      await wrapper.findByRole('button', { name: new RegExp(gitpodText, 'm') }).trigger('click');

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
