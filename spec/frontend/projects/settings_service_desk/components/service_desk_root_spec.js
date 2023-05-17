import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ServiceDeskRoot from '~/projects/settings_service_desk/components/service_desk_root.vue';
import ServiceDeskSetting from '~/projects/settings_service_desk/components/service_desk_setting.vue';

describe('ServiceDeskRoot', () => {
  let axiosMock;
  let wrapper;
  let spy;

  const provideData = {
    customEmail: 'custom.email@example.com',
    customEmailEnabled: true,
    endpoint: '/gitlab-org/gitlab-test/service_desk',
    initialIncomingEmail: 'servicedeskaddress@example.com',
    initialIsEnabled: true,
    outgoingName: 'GitLab Support Bot',
    projectKey: 'key',
    selectedTemplate: 'Bug',
    selectedFileTemplateProjectId: 42,
    templates: ['Bug', 'Documentation'],
    publicProject: false,
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
        customEmail: provideData.customEmail,
        customEmailEnabled: provideData.customEmailEnabled,
        incomingEmail: provideData.initialIncomingEmail,
        initialOutgoingName: provideData.outgoingName,
        initialProjectKey: provideData.projectKey,
        initialSelectedTemplate: provideData.selectedTemplate,
        initialSelectedFileTemplateProjectId: provideData.selectedFileTemplateProjectId,
        isEnabled: provideData.initialIsEnabled,
        isTemplateSaving: false,
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
        '/help/user/project/service_desk.html#use-a-custom-email-address',
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
});
