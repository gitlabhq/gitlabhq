import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ServiceDeskRoot from '~/projects/settings_service_desk/components/service_desk_root.vue';
import ServiceDeskSetting from '~/projects/settings_service_desk/components/service_desk_setting.vue';
import CustomEmailWrapper from '~/projects/settings_service_desk/components/custom_email_wrapper.vue';

describe('ServiceDeskRoot', () => {
  let axiosMock;
  let wrapper;
  let spy;

  const provideData = {
    serviceDeskEmail: 'custom.email@example.com',
    serviceDeskEmailEnabled: true,
    endpoint: '/gitlab-org/gitlab-test/service_desk',
    initialIncomingEmail: 'servicedeskaddress@example.com',
    initialIsEnabled: true,
    isIssueTrackerEnabled: true,
    outgoingName: 'GitLab Support Bot',
    projectKey: 'key',
    areTicketsConfidentialByDefault: false,
    reopenIssueOnExternalParticipantNote: true,
    addExternalParticipantsFromCc: true,
    selectedTemplate: 'Bug',
    selectedFileTemplateProjectId: 42,
    templates: ['Bug', 'Documentation'],
    publicProject: false,
    customEmailEndpoint: '/gitlab-org/gitlab-test/-/service_desk/custom_email',
  };

  const getAlertText = () => wrapper.findComponent(GlAlert).text();

  const createComponent = (customInject = {}) =>
    shallowMount(ServiceDeskRoot, {
      provide: { ...provideData, ...customInject },
      stubs: { GlSprintf },
    });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    spy = jest.spyOn(axios, 'put');
  });

  afterEach(() => {
    axiosMock.restore();
    if (spy) {
      spy.mockRestore();
    }
  });

  describe('ServiceDeskSetting component', () => {
    it('is rendered', () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(ServiceDeskSetting).props()).toEqual({
        serviceDeskEmail: provideData.serviceDeskEmail,
        serviceDeskEmailEnabled: provideData.serviceDeskEmailEnabled,
        incomingEmail: provideData.initialIncomingEmail,
        initialOutgoingName: provideData.outgoingName,
        initialProjectKey: provideData.projectKey,
        initialAreTicketsConfidentialByDefault: provideData.areTicketsConfidentialByDefault,
        initialReopenIssueOnExternalParticipantNote:
          provideData.reopenIssueOnExternalParticipantNote,
        initialAddExternalParticipantsFromCc: provideData.addExternalParticipantsFromCc,
        initialSelectedTemplate: provideData.selectedTemplate,
        initialSelectedFileTemplateProjectId: provideData.selectedFileTemplateProjectId,
        isEnabled: provideData.initialIsEnabled,
        isIssueTrackerEnabled: provideData.isIssueTrackerEnabled,
        isTemplateSaving: false,
        publicProject: provideData.publicProject,
        templates: provideData.templates,
      });
    });

    it('shows alert about email inference when current project is public', () => {
      wrapper = createComponent({
        publicProject: true,
      });

      const alertEl = wrapper.find('[data-testid="public-project-alert"]');
      expect(alertEl.exists()).toBe(true);
      expect(alertEl.text()).toContain(
        'This project is public. Non-members can guess the Service Desk email address, because it contains the group and project name.',
      );

      const alertBodyLink = alertEl.findComponent(GlLink);
      expect(alertBodyLink.exists()).toBe(true);
      expect(alertBodyLink.attributes('href')).toBe(
        '/help/user/project/service_desk/configure.html#use-an-additional-service-desk-alias-email',
      );
      expect(alertBodyLink.text()).toBe('How do I create a custom email address?');
    });

    describe('toggle event', () => {
      describe('when toggling service desk on', () => {
        beforeEach(async () => {
          wrapper = createComponent();

          wrapper.findComponent(ServiceDeskSetting).vm.$emit('toggle', true);

          await waitForPromises();
        });

        it('sends a request to turn service desk on', () => {
          axiosMock.onPut(provideData.endpoint).replyOnce(HTTP_STATUS_OK);

          expect(spy).toHaveBeenCalledWith(provideData.endpoint, { service_desk_enabled: true });
        });

        it('shows a message when there is an error', () => {
          axiosMock.onPut(provideData.endpoint).networkError();

          expect(getAlertText()).toContain('An error occurred while enabling Service Desk.');
        });
      });

      describe('when toggling service desk off', () => {
        beforeEach(async () => {
          wrapper = createComponent();

          wrapper.findComponent(ServiceDeskSetting).vm.$emit('toggle', false);

          await waitForPromises();
        });

        it('sends a request to turn service desk off', () => {
          axiosMock.onPut(provideData.endpoint).replyOnce(HTTP_STATUS_OK);

          expect(spy).toHaveBeenCalledWith(provideData.endpoint, { service_desk_enabled: false });
        });

        it('shows a message when there is an error', () => {
          axiosMock.onPut(provideData.endpoint).networkError();

          expect(getAlertText()).toContain('An error occurred while disabling Service Desk.');
        });
      });
    });

    describe('save event', () => {
      describe('successful request', () => {
        beforeEach(async () => {
          axiosMock.onPut(provideData.endpoint).replyOnce(HTTP_STATUS_OK);

          wrapper = createComponent();

          const payload = {
            selectedTemplate: 'Bug',
            outgoingName: 'GitLab Support Bot',
            projectKey: 'key',
            areTicketsConfidentialByDefault: false,
            reopenIssueOnExternalParticipantNote: true,
            addExternalParticipantsFromCc: true,
          };

          wrapper.findComponent(ServiceDeskSetting).vm.$emit('save', payload);

          await waitForPromises();
        });

        it('sends a request to update template', () => {
          expect(spy).toHaveBeenCalledWith(provideData.endpoint, {
            issue_template_key: 'Bug',
            outgoing_name: 'GitLab Support Bot',
            project_key: 'key',
            service_desk_enabled: true,
            tickets_confidential_by_default: false,
            reopen_issue_on_external_participant_note: true,
            add_external_participants_from_cc: true,
          });
        });

        it('shows success message', () => {
          expect(getAlertText()).toContain('Changes saved.');
        });
      });

      describe('unsuccessful request', () => {
        beforeEach(async () => {
          axiosMock.onPut(provideData.endpoint).networkError();

          wrapper = createComponent();

          const payload = {
            selectedTemplate: 'Bug',
            outgoingName: 'GitLab Support Bot',
            projectKey: 'key',
            tickets_confidential_by_default: false,
            reopen_issue_on_external_participant_note: true,
            addExternalParticipantsFromCc: true,
          };

          wrapper.findComponent(ServiceDeskSetting).vm.$emit('save', payload);

          await waitForPromises();
        });

        it('shows an error message', () => {
          expect(getAlertText()).toContain('An error occurred while saving changes:');
        });
      });
    });
  });

  describe('CustomEmailWrapper component', () => {
    it('is rendered', () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(CustomEmailWrapper).exists()).toBe(true);
      expect(wrapper.findComponent(CustomEmailWrapper).props()).toEqual({
        incomingEmail: provideData.initialIncomingEmail,
        customEmailEndpoint: provideData.customEmailEndpoint,
      });
    });

    describe('when Service Desk is disabled', () => {
      beforeEach(() => {
        wrapper = createComponent({ initialIsEnabled: false });
      });

      it('is not rendered', () => {
        expect(wrapper.findComponent(CustomEmailWrapper).exists()).toBe(false);
      });
    });

    describe('when issue tracker is disabled', () => {
      beforeEach(() => {
        wrapper = createComponent({ isIssueTrackerEnabled: false });
      });

      it('is not rendered', () => {
        expect(wrapper.findComponent(CustomEmailWrapper).exists()).toBe(false);
      });
    });
  });
});
