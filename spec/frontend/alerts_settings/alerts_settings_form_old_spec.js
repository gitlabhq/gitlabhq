import { shallowMount } from '@vue/test-utils';
import { GlModal, GlAlert } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form_old.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import { i18n } from '~/alerts_settings/constants';
import service from '~/alerts_settings/services';
import { defaultAlertSettingsConfig } from './util';

jest.mock('~/alerts_settings/services');

describe('AlertsSettingsFormOld', () => {
  let wrapper;

  const createComponent = ({ methods } = {}, data) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      provide: {
        ...defaultAlertSettingsConfig,
      },
      methods,
    });
  };

  const findSelect = () => wrapper.find('[data-testid="alert-settings-select"]');
  const findJsonInput = () => wrapper.find('#alert-json');
  const findUrl = () => wrapper.find('#url');
  const findAuthorizationKey = () => wrapper.find('#authorization-key');
  const findApiUrl = () => wrapper.find('#api-url');

  beforeEach(() => {
    setFixtures(`
    <div>
      <span class="js-service-active-status fa fa-circle" data-value="true"></span>
      <span class="js-service-active-status fa fa-power-off" data-value="false"></span>
    </div>`);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the initial template', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  describe('reset key', () => {
    it('triggers resetKey method', () => {
      const resetKey = jest.fn();
      const methods = { resetKey };
      createComponent({ methods });

      wrapper.find(GlModal).vm.$emit('ok');

      expect(resetKey).toHaveBeenCalled();
    });

    it('updates the authorization key on success', () => {
      createComponent(
        {},
        {
          authKey: 'newToken',
        },
      );

      expect(findAuthorizationKey().attributes('value')).toBe('newToken');
    });

    it('shows a alert message on error', () => {
      service.updateGenericKey.mockRejectedValueOnce({});

      createComponent();

      return wrapper.vm.resetKey().then(() => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
      });
    });
  });

  describe('activate toggle', () => {
    it('triggers toggleActivated method', () => {
      const toggleService = jest.fn();
      const methods = { toggleService };
      createComponent({ methods });

      wrapper.find(ToggleButton).vm.$emit('change', true);
      expect(toggleService).toHaveBeenCalled();
    });

    describe('error is encountered', () => {
      it('restores previous value', () => {
        service.updateGenericKey.mockRejectedValueOnce({});
        createComponent();
        return wrapper.vm.resetKey().then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(false);
        });
      });
    });
  });

  describe('prometheus is active', () => {
    beforeEach(() => {
      createComponent(
        {},
        {
          selectedIntegration: 'PROMETHEUS',
        },
      );
    });

    it('renders a valid "select"', () => {
      expect(findSelect().exists()).toBe(true);
    });

    it('shows the API URL input', () => {
      expect(findApiUrl().exists()).toBe(true);
    });

    it('shows the correct default API URL', () => {
      expect(findUrl().attributes('value')).toBe(defaultAlertSettingsConfig.prometheus.url);
    });
  });

  describe('Opsgenie is active', () => {
    beforeEach(() => {
      createComponent(
        {},
        {
          selectedIntegration: 'OPSGENIE',
        },
      );
    });

    it('shows a input for the Opsgenie target URL', () => {
      expect(findApiUrl().exists()).toBe(true);
    });
  });

  describe('trigger test alert', () => {
    beforeEach(() => {
      createComponent({});
    });

    it('should enable the JSON input', () => {
      expect(findJsonInput().exists()).toBe(true);
      expect(findJsonInput().props('value')).toBe(null);
    });

    it('should validate JSON input', async () => {
      createComponent(true, {
        testAlertJson: '{ "value": "test" }',
      });

      findJsonInput().vm.$emit('change');

      await wrapper.vm.$nextTick();

      expect(findJsonInput().attributes('state')).toBe('true');
    });

    describe('alert service is toggled', () => {
      describe('error handling', () => {
        const toggleService = true;

        it('should show generic error', async () => {
          service.updateGenericActive.mockRejectedValueOnce({});

          createComponent();

          await wrapper.vm.toggleActivated(toggleService);
          expect(wrapper.vm.active).toBe(false);
          expect(wrapper.find(GlAlert).attributes('variant')).toBe('danger');
          expect(wrapper.find(GlAlert).text()).toBe(i18n.errorMsg);
        });

        it('should show first field specific error when available', async () => {
          const err1 = "can't be blank";
          const err2 = 'is not a valid URL';
          const key = 'api_url';
          service.updateGenericActive.mockRejectedValueOnce({
            response: { data: { errors: { [key]: [err1, err2] } } },
          });

          createComponent();

          await wrapper.vm.toggleActivated(toggleService);

          expect(wrapper.find(GlAlert).text()).toContain(i18n.errorMsg);
          expect(wrapper.find(GlAlert).text()).toContain(`${key} ${err1}`);
        });
      });
    });
  });
});
