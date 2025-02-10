import { GlButton, GlDropdown, GlLoadingIcon, GlToggle, GlAlert } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import ServiceDeskSetting from '~/projects/settings_service_desk/components/service_desk_setting.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('ServiceDeskSetting', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findIncomingEmail = () => wrapper.findByTestId('incoming-email');
  const findIncomingEmailLabel = () => wrapper.findByTestId('incoming-email-label');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTemplateDropdown = () => wrapper.findComponent(GlDropdown);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findSuffixFormGroup = () => wrapper.findByTestId('suffix-form-group');
  const findIssueTrackerInfo = () => wrapper.findComponent(GlAlert);
  const findIssueHelpLink = () => wrapper.findByTestId('issue-help-page');
  const findAreTicketsConfidentialByDefaultWrapper = () =>
    wrapper.findByTestId('service-desk-are-tickets-confidential-by-default-wrapper');
  const findAreTicketsConfidentialByDefaultCheckbox = () =>
    wrapper.findByTestId('service-desk-are-tickets-confidential-by-default');
  const findReopenIssueOnExternalParticipantNoteCheckbox = () =>
    wrapper.findByTestId('reopen-issue-on-external-participant-note');
  const findAddExternalParticipantsFromCcCheckbox = () =>
    wrapper.findByTestId('add-external-participants-from-cc');

  const createComponent = ({ props = {}, provide = {} } = {}) =>
    extendedWrapper(
      mount(ServiceDeskSetting, {
        propsData: {
          isEnabled: true,
          isIssueTrackerEnabled: true,
          ...props,
        },
        provide: {
          glFeatures: {
            issueEmailParticipants: true,
          },
          ...provide,
        },
      }),
    );

  describe('with issue tracker', () => {
    it('does not show the info notice when enabled', () => {
      wrapper = createComponent();

      expect(findIssueTrackerInfo().exists()).toBe(false);
    });

    it('shows info notice when disabled with help page link', () => {
      wrapper = createComponent({
        props: {
          isIssueTrackerEnabled: false,
        },
      });

      expect(findIssueTrackerInfo().exists()).toBe(true);
      expect(findIssueHelpLink().text()).toEqual('activate the issue tracker');
      expect(findIssueHelpLink().attributes('href')).toBe(
        helpPagePath('user/project/settings/_index', {
          anchor: 'configure-project-features-and-permissions',
        }),
      );
    });
  });

  describe('when isEnabled=true', () => {
    describe('only isEnabled', () => {
      describe('as project admin', () => {
        beforeEach(() => {
          wrapper = createComponent();
        });

        it('should see activation checkbox', () => {
          expect(findToggle().props('label')).toBe(ServiceDeskSetting.i18n.toggleLabel);
        });

        it('should see main panel with the email info', () => {
          expect(findIncomingEmailLabel().exists()).toBe(true);
        });

        it('should see loading spinner and not the incoming email', () => {
          expect(findLoadingIcon().exists()).toBe(true);
          expect(findIncomingEmail().exists()).toBe(false);
        });

        it('should display help text', () => {
          expect(findSuffixFormGroup().text()).toContain(
            'To add a custom suffix, set up a Service Desk email address',
          );
          expect(findSuffixFormGroup().text()).not.toContain(
            'Add a suffix to Service Desk email address',
          );
        });
      });
    });

    describe('service desk email "from" name', () => {
      it('service desk e-mail "from" name input appears', () => {
        wrapper = createComponent();

        const input = wrapper.findByTestId('email-from-name');

        expect(input.exists()).toBe(true);
        expect(input.attributes('disabled')).toBeUndefined();
      });
    });

    describe('service desk toggle', () => {
      it('emits an event to turn on Service Desk when clicked', async () => {
        wrapper = createComponent();

        findToggle().vm.$emit('change', true);

        await nextTick();

        expect(wrapper.emitted('toggle')[0]).toEqual([true]);
      });
    });

    describe('with incomingEmail', () => {
      const incomingEmail = 'foo@bar.com';

      beforeEach(() => {
        wrapper = createComponent({
          props: { incomingEmail },
        });
      });

      it('should see email and not the loading spinner', () => {
        expect(findIncomingEmail().element.value).toEqual(incomingEmail);
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('renders a copy to clipboard button', () => {
        expect(findClipboardButton().exists()).toBe(true);
        expect(findClipboardButton().props()).toEqual(
          expect.objectContaining({
            title: 'Copy',
            text: incomingEmail,
          }),
        );
      });
    });

    describe('with serviceDeskEmail', () => {
      describe('serviceDeskEmail is different than incomingEmail', () => {
        const incomingEmail = 'foo@bar.com';
        const serviceDeskEmail = 'servicedesk@bar.com';

        beforeEach(() => {
          wrapper = createComponent({
            props: { incomingEmail, serviceDeskEmail },
          });
        });

        it('should see service desk email', () => {
          expect(findIncomingEmail().element.value).toEqual(serviceDeskEmail);
        });
      });

      describe('project suffix', () => {
        it('input is hidden', () => {
          wrapper = createComponent({
            props: { serviceDeskEmailEnabled: false },
          });

          const input = wrapper.findByTestId('project-suffix');

          expect(input.exists()).toBe(false);
        });

        it('input is enabled', () => {
          wrapper = createComponent({
            props: { serviceDeskEmailEnabled: true },
          });

          const input = wrapper.findByTestId('project-suffix');

          expect(input.exists()).toBe(true);
          expect(input.attributes('disabled')).toBeUndefined();
        });

        it('shows error when value contains uppercase or special chars', async () => {
          wrapper = createComponent({
            props: { email: 'foo@bar.com', serviceDeskEmailEnabled: true },
          });

          const input = wrapper.findByTestId('project-suffix');

          input.setValue('abc_A.');
          input.trigger('blur');

          await nextTick();

          const errorText = wrapper.find('.invalid-feedback');
          expect(errorText.exists()).toBe(true);
        });
      });

      describe('serviceDeskEmail is the same as incomingEmail', () => {
        const email = 'foo@bar.com';

        beforeEach(() => {
          wrapper = createComponent({
            props: { incomingEmail: email, serviceDeskEmail: email },
          });
        });

        it('should see service desk email', () => {
          expect(findIncomingEmail().element.value).toEqual(email);
        });
      });
    });
  });

  describe('are tickets confidential by default checkbox', () => {
    it('is rendered', () => {
      wrapper = createComponent();

      expect(findAreTicketsConfidentialByDefaultCheckbox().exists()).toBe(true);
    });

    describe('when project is public', () => {
      beforeEach(() => {
        wrapper = createComponent({
          props: { publicProject: true, initialAreTicketsConfidentialByDefault: false },
        });
      });

      it('displays correct help text', () => {
        expect(findAreTicketsConfidentialByDefaultWrapper().text()).toContain(
          ServiceDeskSetting.i18n.areTicketsConfidentialByDefault.help.publicProject,
        );
      });

      it('checks and disables the checkbox', () => {
        const { element } = findAreTicketsConfidentialByDefaultCheckbox().find('input');

        expect(element.checked).toBe(true);
        expect(element.disabled).toBe(true);
      });
    });

    describe('when project is not public', () => {
      describe('when tickets are confidential by default', () => {
        beforeEach(() => {
          wrapper = createComponent({ props: { initialAreTicketsConfidentialByDefault: true } });
        });

        it('forwards true as initial value to the checkbox', () => {
          expect(findAreTicketsConfidentialByDefaultCheckbox().find('input').element.checked).toBe(
            true,
          );
        });

        it('displays correct help text', () => {
          expect(findAreTicketsConfidentialByDefaultWrapper().text()).toContain(
            ServiceDeskSetting.i18n.areTicketsConfidentialByDefault.help.confidential,
          );
        });
      });

      describe('when tickets are not confidential by default', () => {
        beforeEach(() => {
          wrapper = createComponent({ props: { initialAreTicketsConfidentialByDefault: false } });
        });

        it('forwards false as initial value to the checkbox', () => {
          expect(findAreTicketsConfidentialByDefaultCheckbox().find('input').element.checked).toBe(
            false,
          );
        });

        it('displays correct help text', () => {
          expect(findAreTicketsConfidentialByDefaultWrapper().text()).toContain(
            ServiceDeskSetting.i18n.areTicketsConfidentialByDefault.help.nonConfidential,
          );
        });
      });
    });
  });

  describe('reopen issue on external participant note checkbox', () => {
    it('is rendered', () => {
      wrapper = createComponent();
      expect(findReopenIssueOnExternalParticipantNoteCheckbox().exists()).toBe(true);
    });

    it('forwards false as initial value to the checkbox', () => {
      wrapper = createComponent({ props: { initialReopenIssueOnExternalParticipantNote: false } });
      expect(findReopenIssueOnExternalParticipantNoteCheckbox().find('input').element.checked).toBe(
        false,
      );
    });

    it('forwards true as initial value to the checkbox', () => {
      wrapper = createComponent({ props: { initialReopenIssueOnExternalParticipantNote: true } });
      expect(findReopenIssueOnExternalParticipantNoteCheckbox().find('input').element.checked).toBe(
        true,
      );
    });
  });

  describe('add external participants from cc checkbox', () => {
    it('is rendered', () => {
      wrapper = createComponent();
      expect(findAddExternalParticipantsFromCcCheckbox().exists()).toBe(true);
    });

    it('forwards the initial value to the checkbox', () => {
      wrapper = createComponent({ props: { initialAddExternalParticipantsFromCc: true } });
      expect(findAddExternalParticipantsFromCcCheckbox().find('input').element.checked).toBe(true);
    });

    describe('when feature flag issue_email_participants is disabled', () => {
      it('is not rendered', () => {
        wrapper = createComponent({ provide: { glFeatures: { issueEmailParticipants: false } } });
        expect(findAddExternalParticipantsFromCcCheckbox().exists()).toBe(false);
      });
    });
  });

  describe('save button', () => {
    it('renders a save button to save a template', () => {
      wrapper = createComponent();
      const saveButton = findButton();

      expect(saveButton.text()).toContain('Save changes');
      expect(saveButton.props()).toMatchObject({
        variant: 'confirm',
      });
    });

    it('emits a save event with the chosen template when the save button is clicked', async () => {
      wrapper = createComponent({
        props: {
          initialSelectedTemplate: 'Bug',
          initialSelectedFileTemplateProjectId: 42,
          initialOutgoingName: 'GitLab Support Bot',
          initialProjectKey: 'key',
          initialAreTicketsConfidentialByDefault: false,
          initialReopenIssueOnExternalParticipantNote: true,
          initialAddExternalParticipantsFromCc: true,
        },
      });

      findButton().vm.$emit('click');

      await nextTick();

      const payload = {
        selectedTemplate: 'Bug',
        fileTemplateProjectId: 42,
        outgoingName: 'GitLab Support Bot',
        projectKey: 'key',
        areTicketsConfidentialByDefault: false,
        reopenIssueOnExternalParticipantNote: true,
        addExternalParticipantsFromCc: true,
      };

      expect(wrapper.emitted('save')[0]).toEqual([payload]);
    });
  });

  describe('when isEnabled=false', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: { isEnabled: false },
      });
    });

    it('does not render email panel', () => {
      expect(findIncomingEmailLabel().exists()).toBe(false);
    });

    it('does not render template dropdown', () => {
      expect(findTemplateDropdown().exists()).toBe(false);
    });

    it('does not render template save button', () => {
      expect(findButton().exists()).toBe(false);
    });

    it('does not render reopen issue on external participant note checkbox', () => {
      expect(findReopenIssueOnExternalParticipantNoteCheckbox().exists()).toBe(false);
    });

    it('does not render add external participants from cc checkbox', () => {
      expect(findAddExternalParticipantsFromCcCheckbox().exists()).toBe(false);
    });

    it('emits an event to turn on Service Desk when the toggle is clicked', async () => {
      findToggle().vm.$emit('change', false);

      await nextTick();

      expect(wrapper.emitted('toggle')[0]).toEqual([false]);
    });
  });
});
