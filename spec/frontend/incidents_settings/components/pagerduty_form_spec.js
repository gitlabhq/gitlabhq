import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { GlAlert, GlModal } from '@gitlab/ui';
import PagerDutySettingsForm from '~/incidents_settings/components/pagerduty_form.vue';

describe('Alert integration settings form', () => {
  let wrapper;
  const resetWebhookUrl = jest.fn();
  const service = { updateSettings: jest.fn().mockResolvedValue(), resetWebhookUrl };

  const findForm = () => wrapper.find({ ref: 'settingsForm' });
  const findWebhookInput = () => wrapper.find('[data-testid="webhook-url"]');
  const findModal = () => wrapper.find(GlModal);
  const findAlert = () => wrapper.find(GlAlert);

  beforeEach(() => {
    wrapper = shallowMount(PagerDutySettingsForm, {
      provide: {
        service,
        pagerDutySettings: {
          active: true,
          webhookUrl: 'pagerduty.webhook.com',
          webhookUpdateEndpoint: 'webhook/update',
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('should match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should call service `updateSettings` on form submit', () => {
    findForm().trigger('submit');
    expect(service.updateSettings).toHaveBeenCalledWith(
      expect.objectContaining({ pagerduty_active: wrapper.vm.active }),
    );
  });

  describe('Webhook reset', () => {
    it('should make a call for webhook reset and reset form values', async () => {
      const newWebhookUrl = 'new.webhook.url?token=token';
      resetWebhookUrl.mockResolvedValueOnce({
        data: { pagerduty_webhook_url: newWebhookUrl },
      });
      findModal().vm.$emit('ok');
      await waitForPromises();
      expect(resetWebhookUrl).toHaveBeenCalled();
      expect(findWebhookInput().attributes('value')).toBe(newWebhookUrl);
      expect(findAlert().attributes('variant')).toBe('success');
    });

    it('should show error message and NOT reset webhook url', async () => {
      resetWebhookUrl.mockRejectedValueOnce();
      findModal().vm.$emit('ok');
      await waitForPromises();
      expect(findAlert().attributes('variant')).toBe('danger');
    });
  });
});
