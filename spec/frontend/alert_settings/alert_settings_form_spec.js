import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { GlModal, GlAlert } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import IntegrationsList from '~/alerts_settings/components/alerts_integrations_list.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';

const PROMETHEUS_URL = '/prometheus/alerts/notify.json';
const GENERIC_URL = '/alerts/notify.json';
const KEY = 'abcedfg123';
const INVALID_URL = 'http://invalid';
const ACTIVATED = false;

describe('AlertsSettingsForm', () => {
  let wrapper;
  let mockAxios;

  const createComponent = ({ methods } = {}, data) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      provide: {
        generic: {
          authorizationKey: KEY,
          formPath: INVALID_URL,
          url: GENERIC_URL,
          alertsSetupUrl: INVALID_URL,
          alertsUsageUrl: INVALID_URL,
          activated: ACTIVATED,
        },
        prometheus: {
          authorizationKey: KEY,
          prometheusFormPath: INVALID_URL,
          prometheusUrl: PROMETHEUS_URL,
          activated: ACTIVATED,
        },
        opsgenie: {
          opsgenieMvcIsAvailable: true,
          formPath: INVALID_URL,
          activated: ACTIVATED,
          opsgenieMvcTargetUrl: GENERIC_URL,
        },
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
    mockAxios = new MockAdapter(axios);
    setFixtures(`
    <div>
      <span class="js-service-active-status fa fa-circle" data-value="true"></span>
      <span class="js-service-active-status fa fa-power-off" data-value="false"></span>
    </div>`);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the initial template', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });

  it('renders alerts integrations list', () => {
    createComponent();
    expect(wrapper.find(IntegrationsList).exists()).toBe(true);
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
      const formPath = 'some/path';
      mockAxios.onPut(formPath).replyOnce(404);

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
        const formPath = 'some/path';
        mockAxios.onPut(formPath).replyOnce(500);
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
          selectedEndpoint: 'prometheus',
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
      expect(findUrl().attributes('value')).toBe(PROMETHEUS_URL);
    });
  });

  describe('Opsgenie is active', () => {
    beforeEach(() => {
      createComponent(
        {},
        {
          selectedEndpoint: 'opsgenie',
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
      it('should show a error alert if failed', () => {
        const formPath = 'some/path';
        const toggleService = true;
        mockAxios.onPut(formPath).replyOnce(422, {
          errors: 'Error message to display',
        });

        createComponent();

        return wrapper.vm.toggleActivated(toggleService).then(() => {
          expect(wrapper.vm.active).toBe(false);
          expect(wrapper.find(GlAlert).attributes('variant')).toBe('danger');
        });
      });
    });
  });
});
