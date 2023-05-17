import { shallowMount } from '@vue/test-utils';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_form.vue';

describe('Alert integration settings form', () => {
  let wrapper;
  const service = { updateSettings: jest.fn().mockResolvedValue() };

  const findForm = () => wrapper.findComponent({ ref: 'settingsForm' });

  beforeEach(() => {
    wrapper = shallowMount(AlertsSettingsForm, {
      provide: {
        service,
        alertSettings: {
          issueTemplateKey: 'selecte_tmpl',
          createIssue: true,
          sendEmail: false,
          templates: [],
          autoCloseIncident: true,
        },
      },
    });
  });

  describe('default state', () => {
    it('should match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('form', () => {
    it('should call service `updateSettings` on submit', () => {
      findForm().trigger('submit');
      expect(service.updateSettings).toHaveBeenCalledWith(
        expect.objectContaining({
          create_issue: wrapper.vm.createIssueEnabled,
          issue_template_key: wrapper.vm.issueTemplate,
          send_email: wrapper.vm.sendEmailEnabled,
          auto_close_incident: wrapper.vm.autoCloseIncident,
        }),
      );
    });
  });
});
