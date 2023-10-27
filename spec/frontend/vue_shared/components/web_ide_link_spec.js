import { GlModal, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { omit } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import getWritableForksResponse from 'test_fixtures/graphql/vue_shared/components/web_ide/get_writable_forks.query.graphql_none.json';
import WebIdeLink, { i18n } from '~/vue_shared/components/web_ide_link.vue';
import ConfirmForkModal from '~/vue_shared/components/web_ide/confirm_fork_modal.vue';

import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking } from 'helpers/tracking_helper';
import {
  shallowMountExtended,
  mountExtended,
  extendedWrapper,
} from 'helpers/vue_test_utils_helper';

import { visitUrl } from '~/lib/utils/url_utility';
import getWritableForksQuery from '~/vue_shared/components/web_ide/get_writable_forks.query.graphql';

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
  handle: undefined,
  text: 'Edit single file',
  secondaryText: 'Edit this file only.',
  attrs: {
    'data-testid': 'edit-menu-item',
  },
  tracking: {
    action: 'click_consolidated_edit',
    label: 'single_file',
  },
};
const ACTION_EDIT_CONFIRM_FORK = {
  ...ACTION_EDIT,
  href: '#modal-confirm-fork-edit',
  handle: expect.any(Function),
};
const ACTION_WEB_IDE = {
  secondaryText: i18n.webIdeText,
  text: 'Web IDE',
  attrs: {
    'data-testid': 'webide-menu-item',
  },
  href: undefined,
  handle: expect.any(Function),
  tracking: {
    action: 'click_consolidated_edit',
    label: 'web_ide',
  },
};
const ACTION_WEB_IDE_CONFIRM_FORK = {
  ...ACTION_WEB_IDE,
  handle: expect.any(Function),
};
const ACTION_WEB_IDE_EDIT_FORK = { ...ACTION_WEB_IDE, text: 'Edit fork in Web IDE' };
const ACTION_GITPOD = {
  href: TEST_GITPOD_URL,
  handle: undefined,
  secondaryText: 'Launch a ready-to-code development environment for your project.',
  text: 'Gitpod',
  attrs: {
    'data-testid': 'gitpod-menu-item',
  },
  tracking: {
    action: 'click_consolidated_edit',
    label: 'gitpod',
  },
};
const ACTION_GITPOD_ENABLE = {
  ...ACTION_GITPOD,
  href: undefined,
  handle: expect.any(Function),
};
const ACTION_PIPELINE_EDITOR = {
  href: TEST_PIPELINE_EDITOR_URL,
  secondaryText: 'Edit, lint, and visualize your pipeline.',
  text: 'Edit in pipeline editor',
  attrs: {
    'data-testid': 'pipeline_editor-menu-item',
  },
  tracking: {
    action: 'click_consolidated_edit',
    label: 'pipeline_editor',
  },
};

describe('vue_shared/components/web_ide_link', () => {
  Vue.use(VueApollo);

  let wrapper;
  let trackingSpy;

  function createComponent(props, { mountFn = shallowMountExtended, slots = {} } = {}) {
    const fakeApollo = createMockApollo([
      [getWritableForksQuery, jest.fn().mockResolvedValue(getWritableForksResponse)],
    ]);
    wrapper = mountFn(WebIdeLink, {
      propsData: {
        editUrl: TEST_EDIT_URL,
        webIdeUrl: TEST_WEB_IDE_URL,
        gitpodUrl: TEST_GITPOD_URL,
        pipelineEditorUrl: TEST_PIPELINE_EDITOR_URL,
        forkPath,
        ...props,
      },
      slots,
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <slot></slot>
              <slot name="modal-footer"></slot>
            </div>`,
        }),
        GlDisclosureDropdownItem,
      },
      apolloProvider: fakeApollo,
    });

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  }

  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForkConfirmModal = () => wrapper.findComponent(ConfirmForkModal);
  const getDropdownItemsAsData = () =>
    findDisclosureDropdownItems().wrappers.map((item) => {
      const extendedWrapperItem = extendedWrapper(item);
      const attributes = extendedWrapperItem.attributes();
      const props = extendedWrapperItem.props();

      return {
        text: extendedWrapperItem.findByTestId('action-primary-text').text(),
        secondaryText: extendedWrapperItem.findByTestId('action-secondary-text').text(),
        href: props.item.href,
        handle: props.item.handle,
        attrs: {
          'data-testid': attributes['data-testid'],
        },
      };
    });
  const omitTrackingParams = (actions) => actions.map((action) => omit(action, 'tracking'));

  describe.each([
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
  ])('for a set of props', ({ props, expectedActions }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it('renders the appropiate actions', () => {
      // omit tracking property because it is not included in the dropdown item
      expect(getDropdownItemsAsData()).toEqual(omitTrackingParams(expectedActions));
    });

    describe('when an action is clicked', () => {
      it('tracks event', () => {
        expectedActions.forEach((action, index) => {
          findDisclosureDropdownItems().at(index).vm.$emit('action');

          expect(trackingSpy).toHaveBeenCalledWith(undefined, action.tracking.action, {
            label: action.tracking.label,
          });
        });
      });
    });
  });

  it('bubbles up shown and hidden events triggered by actions button component', () => {
    createComponent();

    expect(wrapper.emitted('shown')).toBe(undefined);
    expect(wrapper.emitted('hidden')).toBe(undefined);

    findDisclosureDropdown().vm.$emit('shown');
    findDisclosureDropdown().vm.$emit('hidden');

    expect(wrapper.emitted('shown')).toHaveLength(1);
    expect(wrapper.emitted('hidden')).toHaveLength(1);
  });

  it.each(['before-actions', 'after-actions'])('exposes a %s slot', (slot) => {
    const slotContent = 'slot content';

    createComponent({}, { slots: { [slot]: slotContent } });

    expect(wrapper.text()).toContain(slotContent);
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
      expect(getDropdownItemsAsData()).toEqual(
        omitTrackingParams([ACTION_PIPELINE_EDITOR, ACTION_WEB_IDE, ACTION_GITPOD]),
      );
    });

    it('when web ide button is clicked it opens in a new tab', async () => {
      findDisclosureDropdownItems().at(1).props().item.handle();
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

        findDisclosureDropdownItems().at(0).props().item.handle();

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

      findDisclosureDropdownItems().at(0).props().item.handle();

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
