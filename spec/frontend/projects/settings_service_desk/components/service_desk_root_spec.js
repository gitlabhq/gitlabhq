import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
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
    templates: ['Bug', 'Documentation'],
  };

  const getAlertText = () => wrapper.find(GlAlert).text();

  const createComponent = () => shallowMount(ServiceDeskRoot, { provide: provideData });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    spy = jest.spyOn(axios, 'put');
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
    if (spy) {
      spy.mockRestore();
    }
  });

  describe('ServiceDeskSetting component', () => {
    it('is rendered', () => {
      wrapper = createComponent();

      expect(wrapper.find(ServiceDeskSetting).props()).toEqual({
        customEmail: provideData.customEmail,
        customEmailEnabled: provideData.customEmailEnabled,
        incomingEmail: provideData.initialIncomingEmail,
        initialOutgoingName: provideData.outgoingName,
        initialProjectKey: provideData.projectKey,
        initialSelectedTemplate: provideData.selectedTemplate,
        isEnabled: provideData.initialIsEnabled,
        isTemplateSaving: false,
        templates: provideData.templates,
      });
    });

    describe('toggle event', () => {
      describe('when toggling service desk on', () => {
        beforeEach(async () => {
          wrapper = createComponent();

          wrapper.find(ServiceDeskSetting).vm.$emit('toggle', true);

          await waitForPromises();
        });

        it('sends a request to turn service desk on', () => {
          axiosMock.onPut(provideData.endpoint).replyOnce(httpStatusCodes.OK);

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

          wrapper.find(ServiceDeskSetting).vm.$emit('toggle', false);

          await waitForPromises();
        });

        it('sends a request to turn service desk off', () => {
          axiosMock.onPut(provideData.endpoint).replyOnce(httpStatusCodes.OK);

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
          axiosMock.onPut(provideData.endpoint).replyOnce(httpStatusCodes.OK);

          wrapper = createComponent();

          const payload = {
            selectedTemplate: 'Bug',
            outgoingName: 'GitLab Support Bot',
            projectKey: 'key',
          };

          wrapper.find(ServiceDeskSetting).vm.$emit('save', payload);

          await waitForPromises();
        });

        it('sends a request to update template', async () => {
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

          wrapper.find(ServiceDeskSetting).vm.$emit('save', payload);

          await waitForPromises();
        });

        it('shows an error message', () => {
          expect(getAlertText()).toContain('An error occurred while saving changes:');
        });
      });
    });
  });
});
