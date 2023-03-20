import { GlAlert, GlModal, GlToggle } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PagerDutySettingsForm from '~/incidents_settings/components/pagerduty_form.vue';

describe('Alert integration settings form', () => {
  let wrapper;
  const resetWebhookUrl = jest.fn();
  const service = { updateSettings: jest.fn().mockResolvedValue(), resetWebhookUrl };

  const findWebhookInput = () => wrapper.findByTestId('webhook-url');
  const findFormToggle = () => wrapper.findComponent(GlToggle);
  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    wrapper = shallowMountExtended(PagerDutySettingsForm, {
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

  it('should match the default snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should call service `updateSettings` on toggle change', () => {
    findFormToggle().vm.$emit('change', true);
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
      findModal().vm.$emit('primary');
      await waitForPromises();
      expect(resetWebhookUrl).toHaveBeenCalled();
      expect(findWebhookInput().attributes('value')).toBe(newWebhookUrl);
      expect(findAlert().attributes('variant')).toBe('success');
    });

    it('should show error message and NOT reset webhook url', async () => {
      resetWebhookUrl.mockRejectedValueOnce();
      findModal().vm.$emit('primary');
      await waitForPromises();
      expect(findAlert().attributes('variant')).toBe('danger');
    });
  });
});
