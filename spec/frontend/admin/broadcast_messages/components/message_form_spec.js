import { GlBroadcastMessage, GlForm, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST } from '~/lib/utils/http_status';
import MessageForm from '~/admin/broadcast_messages/components/message_form.vue';
import {
  TYPE_BANNER,
  TYPE_NOTIFICATION,
  THEMES,
  TARGET_OPTIONS,
} from '~/admin/broadcast_messages/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { MOCK_TARGET_ACCESS_LEVELS } from '../mock_data';
import { stubComponent } from '../../../__helpers__/stub_component';

jest.mock('~/alert');

describe('MessageForm', () => {
  let wrapper;
  let axiosMock;

  const defaultProps = {
    message: 'zzzzzzz',
    broadcastType: TYPE_BANNER,
    theme: THEMES[0].value,
    dismissable: false,
    targetPath: '',
    targetAccessLevels: [],
    startsAt: new Date(),
    endsAt: new Date(),
  };

  const messagesPath = '_messages_path_';

  const findPreview = () => wrapper.findComponent(GlBroadcastMessage);
  const findThemeSelect = () => wrapper.findByTestId('theme-select');
  const findDismissable = () => wrapper.findByTestId('dismissable-checkbox');
  const findTargetRoles = () => wrapper.findByTestId('target-roles-checkboxes');
  const findTargetAccessLevelsCheckboxGroup = () =>
    wrapper.findByTestId('target-access-levels-checkbox-group');
  const findSubmitButton = () => wrapper.findByTestId('submit-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findForm = () => wrapper.findComponent(GlForm);
  const findShowInCli = () => wrapper.findByTestId('show-in-cli-checkbox');
  const findTargetSelect = () => wrapper.findByTestId('target-select');
  const findTargetPath = () => wrapper.findByTestId('target-path-input');
  const emitSubmitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  function createComponent({ broadcastMessage = {} } = {}) {
    wrapper = shallowMountExtended(MessageForm, {
      provide: {
        targetAccessLevelOptions: MOCK_TARGET_ACCESS_LEVELS,
        messagesPath,
        previewPath: '_preview_path_',
      },
      propsData: {
        broadcastMessage: {
          ...defaultProps,
          ...broadcastMessage,
        },
      },
      stubs: {
        GlFormSelect: stubComponent(GlFormSelect, {
          props: ['value'],
        }),
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback', 'description'],
        }),
      },
    });
  }

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    createAlert.mockClear();
  });

  describe('the message preview', () => {
    it('renders the preview with the user selected theme', () => {
      const theme = 'blue';
      createComponent({ broadcastMessage: { theme } });
      expect(findPreview().props().theme).toEqual(theme);
    });

    it('renders the placeholder text when the user message is blank', () => {
      createComponent({ broadcastMessage: { message: '  ' } });
      expect(wrapper.text()).toContain(MessageForm.i18n.messagePlaceholder);
    });
  });

  describe('theme select dropdown', () => {
    it('renders for Banners', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_BANNER } });
      expect(findThemeSelect().exists()).toBe(true);
    });

    it('does not render for Notifications', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_NOTIFICATION } });
      expect(findThemeSelect().exists()).toBe(false);
    });
  });

  describe('dismissable checkbox', () => {
    it('renders for Banners', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_BANNER } });
      expect(findDismissable().exists()).toBe(true);
    });

    it('does not render for Notifications', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_NOTIFICATION } });
      expect(findDismissable().exists()).toBe(false);
    });
  });

  describe('showInCli checkbox', () => {
    it('renders for Banners', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_BANNER } });
      expect(findShowInCli().exists()).toBe(true);
    });

    it('does not render for Notifications', () => {
      createComponent({ broadcastMessage: { broadcastType: TYPE_NOTIFICATION } });
      expect(findShowInCli().exists()).toBe(false);
    });
  });

  describe('target select', () => {
    it('renders the first option and hide target path and target roles when creating message', () => {
      createComponent();
      expect(findTargetSelect().props('value')).toBe(TARGET_OPTIONS[0].value);
      expect(findTargetRoles().isVisible()).toBe(false);
      expect(findTargetPath().isVisible()).toBe(false);
    });

    it('triggers displaying target path and target roles when selecting different options', async () => {
      createComponent();
      const targetPath = findTargetPath();
      const targetSelect = findTargetSelect();

      targetSelect.vm.$emit('input', TARGET_OPTIONS[1].value);
      await nextTick();

      expect(targetPath.isVisible()).toBe(true);
      expect(targetPath.props('description')).toBe(MessageForm.i18n.targetPathDescription);
      expect(targetPath.text()).not.toContain(MessageForm.i18n.targetPathWithRolesReminder);
      expect(findTargetRoles().isVisible()).toBe(false);

      targetSelect.vm.$emit('input', TARGET_OPTIONS[2].value);
      await nextTick();
      expect(targetPath.isVisible()).toBe(true);
      expect(targetPath.props('description')).toContain(MessageForm.i18n.targetPathDescription);
      expect(targetPath.props('description')).toContain(
        MessageForm.i18n.targetPathWithRolesReminder,
      );
      expect(findTargetRoles().isVisible()).toBe(true);
    });

    it('renders the second option and hide target roles when editing message with path specified', () => {
      createComponent({ broadcastMessage: { targetPath: '/welcome' } });
      expect(findTargetSelect().props('value')).toBe(TARGET_OPTIONS[1].value);
      expect(findTargetRoles().isVisible()).toBe(false);
      expect(findTargetPath().isVisible()).toBe(true);
    });

    it('renders the third option when editing message with path and roles specified', () => {
      createComponent({ broadcastMessage: { targetPath: '/welcome', targetAccessLevels: [20] } });
      expect(findTargetSelect().props('value')).toBe(TARGET_OPTIONS[2].value);
      expect(findTargetRoles().isVisible()).toBe(true);
      expect(findTargetPath().isVisible()).toBe(true);
    });
  });

  describe('form submit button', () => {
    it('renders the "add" text when the message is not persisted', () => {
      createComponent({ broadcastMessage: { id: undefined } });
      expect(wrapper.text()).toContain(MessageForm.i18n.add);
    });

    it('renders the "update" text when the message is persisted', () => {
      createComponent({ broadcastMessage: { id: 100 } });
      expect(wrapper.text()).toContain(MessageForm.i18n.update);
    });

    it('is disabled when the user message is blank', () => {
      createComponent({ broadcastMessage: { message: '  ' } });
      expect(findSubmitButton().props().disabled).toBe(true);
    });

    it('is not disabled when the user message is present', () => {
      createComponent({ broadcastMessage: { message: 'alsdjfkldsj' } });
      expect(findSubmitButton().props().disabled).toBe(false);
    });
  });

  describe('form cancel button', () => {
    it('renders when the editing a message and has href back to message index page', () => {
      createComponent({ broadcastMessage: { id: 100 } });
      expect(wrapper.text()).toContain('Cancel');
      expect(findCancelButton().attributes('href')).toBe(wrapper.vm.messagesPath);
    });
  });

  describe('form submission', () => {
    const defaultPayload = {
      message: defaultProps.message,
      broadcast_type: defaultProps.broadcastType,
      theme: defaultProps.theme,
      dismissable: defaultProps.dismissable,
      target_path: defaultProps.targetPath,
      target_access_levels: defaultProps.targetAccessLevels,
      starts_at: defaultProps.startsAt,
      ends_at: defaultProps.endsAt,
    };

    describe('when creating a new message', () => {
      beforeEach(() => {
        createComponent({ broadcastMessage: { id: undefined } });
      });

      it('sends a create request for a new message form', async () => {
        emitSubmitForm();
        await waitForPromises();

        expect(axiosMock.history.post).toHaveLength(2);
        expect(axiosMock.history.post[1]).toMatchObject({
          url: messagesPath,
          data: JSON.stringify(defaultPayload),
        });
      });

      it('shows an error alert if the create request fails', async () => {
        axiosMock.onPost(messagesPath).replyOnce(HTTP_STATUS_BAD_REQUEST);
        emitSubmitForm();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: MessageForm.i18n.addError,
          }),
        );
      });
    });

    describe('when editing an existing message', () => {
      const mockId = 1337;

      beforeEach(() => {
        createComponent({ broadcastMessage: { id: mockId } });
      });

      it('sends an update request for a persisted message form', async () => {
        emitSubmitForm();
        await waitForPromises();

        expect(axiosMock.history.patch).toHaveLength(1);
        expect(axiosMock.history.patch[0]).toMatchObject({
          url: `${messagesPath}/${mockId}`,
          data: JSON.stringify(defaultPayload),
        });
      });

      it('shows an error alert if the update request fails', async () => {
        axiosMock.onPost(`${messagesPath}/${mockId}`).replyOnce(HTTP_STATUS_BAD_REQUEST);
        emitSubmitForm();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: MessageForm.i18n.updateError,
          }),
        );
      });

      it('does not submit if target roles is required, and later does submit when validation is corrected', async () => {
        const targetSelect = findTargetSelect();
        targetSelect.vm.$emit('input', TARGET_OPTIONS[2].value);
        await nextTick();

        emitSubmitForm();
        await waitForPromises();

        const targetRolesGroup = findTargetRoles();
        expect(axiosMock.history.patch).toHaveLength(0);
        expect(targetRolesGroup.props('invalidFeedback')).toBe(
          MessageForm.i18n.targetRolesValidationMsg,
        );

        expect(targetRolesGroup.props('state')).toBe(false);

        findTargetAccessLevelsCheckboxGroup().vm.$emit('input', [MOCK_TARGET_ACCESS_LEVELS[0][1]]);
        await nextTick();

        emitSubmitForm();
        await waitForPromises();

        expect(axiosMock.history.patch).toHaveLength(1);
        expect(axiosMock.history.patch[0]).toMatchObject({
          url: `${messagesPath}/${mockId}`,
          data: JSON.stringify({ ...defaultPayload, target_access_levels: [10] }),
        });
      });
    });
  });
});
