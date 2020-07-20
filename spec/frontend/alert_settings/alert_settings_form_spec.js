import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { GlModal, GlAlert } from '@gitlab/ui';
import AlertsSettingsForm from '~/alerts_settings/components/alerts_settings_form.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';

const PROMETHEUS_URL = '/prometheus/alerts/notify.json';
const GENERIC_URL = '/alerts/notify.json';
const KEY = 'abcedfg123';
const INVALID_URL = 'http://invalid';
const ACTIVATED = false;

const defaultProps = {
  generic: {
    initialAuthorizationKey: KEY,
    formPath: INVALID_URL,
    url: GENERIC_URL,
    alertsSetupUrl: INVALID_URL,
    alertsUsageUrl: INVALID_URL,
    activated: ACTIVATED,
  },
  prometheus: {
    prometheusAuthorizationKey: KEY,
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
};

describe('AlertsSettingsForm', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = defaultProps, { methods } = {}, data) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      data() {
        return { ...data };
      },
      propsData: {
        ...defaultProps,
        ...props,
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

  describe('reset key', () => {
    it('triggers resetKey method', () => {
      const resetGenericKey = jest.fn();
      const methods = { resetGenericKey };
      createComponent(defaultProps, { methods });

      wrapper.find(GlModal).vm.$emit('ok');

      expect(resetGenericKey).toHaveBeenCalled();
    });

    it('updates the authorization key on success', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath, { service: { token: '' } }).replyOnce(200, { token: 'newToken' });
      createComponent({ generic: { ...defaultProps.generic, formPath } });

      return wrapper.vm.resetGenericKey().then(() => {
        expect(findAuthorizationKey().attributes('value')).toBe('newToken');
      });
    });

    it('shows a alert message on error', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath).replyOnce(404);

      createComponent({ generic: { ...defaultProps.generic, formPath } });

      return wrapper.vm.resetGenericKey().then(() => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
      });
    });
  });

  describe('activate toggle', () => {
    it('triggers toggleActivated method', () => {
      const toggleService = jest.fn();
      const methods = { toggleService };
      createComponent(defaultProps, { methods });

      wrapper.find(ToggleButton).vm.$emit('change', true);

      expect(toggleService).toHaveBeenCalled();
    });

    describe('error is encountered', () => {
      beforeEach(() => {
        const formPath = 'some/path';
        mockAxios.onPut(formPath).replyOnce(500);
      });

      it('restores previous value', () => {
        createComponent({ generic: { ...defaultProps.generic, initialActivated: false } });
        return wrapper.vm.resetGenericKey().then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(false);
        });
      });
    });
  });

  describe('prometheus is active', () => {
    beforeEach(() => {
      createComponent(
        { prometheus: { ...defaultProps.prometheus, prometheusIsActivated: true } },
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

  describe('opsgenie is active', () => {
    beforeEach(() => {
      createComponent(
        { opsgenie: { ...defaultProps.opsgenie, opsgenieMvcActivated: true } },
        {},
        {
          selectedEndpoint: 'opsgenie',
        },
      );
    });

    it('shows a input for the opsgenie target URL', () => {
      expect(findApiUrl().exists()).toBe(true);
      expect(findSelect().attributes('value')).toBe('opsgenie');
    });
  });

  describe('trigger test alert', () => {
    beforeEach(() => {
      createComponent({ generic: { ...defaultProps.generic, initialActivated: true } }, {}, true);
    });

    it('should enable the JSON input', () => {
      expect(findJsonInput().exists()).toBe(true);
      expect(findJsonInput().props('value')).toBe(null);
    });

    it('should validate JSON input', () => {
      createComponent({ generic: { ...defaultProps.generic } }, true, {
        testAlertJson: '{ "value": "test" }',
      });

      findJsonInput().vm.$emit('change');
      return wrapper.vm.$nextTick().then(() => {
        expect(findJsonInput().attributes('state')).toBe('true');
      });
    });

    describe('alert service is toggled', () => {
      it('should show a info alert if successful', () => {
        const formPath = 'some/path';
        const toggleService = true;
        mockAxios.onPut(formPath).replyOnce(200);

        createComponent({ generic: { ...defaultProps.generic, formPath } });

        return wrapper.vm.toggleActivated(toggleService).then(() => {
          expect(wrapper.find(GlAlert).attributes('variant')).toBe('info');
        });
      });

      it('should show a error alert if failed', () => {
        const formPath = 'some/path';
        const toggleService = true;
        mockAxios.onPut(formPath).replyOnce(422, {
          errors: 'Error message to display',
        });

        createComponent({ generic: { ...defaultProps.generic, formPath } });

        return wrapper.vm.toggleActivated(toggleService).then(() => {
          expect(wrapper.find(GlAlert).attributes('variant')).toBe('danger');
        });
      });
    });
  });
});
