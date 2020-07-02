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
    initialActivated: ACTIVATED,
  },
  prometheus: {
    prometheusAuthorizationKey: KEY,
    prometheusFormPath: INVALID_URL,
    prometheusUrl: PROMETHEUS_URL,
    prometheusIsActivated: ACTIVATED,
  },
};

describe('AlertsSettingsForm', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (
    props = defaultProps,
    { methods } = {},
    alertIntegrationsDropdown = false,
  ) => {
    wrapper = shallowMount(AlertsSettingsForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      methods,
      provide: {
        glFeatures: {
          alertIntegrationsDropdown,
        },
      },
    });
  };

  const findSelect = () => wrapper.find('[data-testid="alert-settings-select"]');
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
      const toggleActivated = jest.fn();
      const methods = { toggleActivated };
      createComponent(defaultProps, { methods });

      wrapper.find(ToggleButton).vm.$emit('change', true);

      expect(toggleActivated).toHaveBeenCalled();
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
        true,
      );
    });

    it('renders a valid "select"', () => {
      expect(findSelect().html()).toMatchSnapshot();
    });

    it('shows the API URL input', () => {
      expect(findApiUrl().exists()).toBe(true);
    });

    it('show a valid Alert URL', () => {
      expect(findUrl().exists()).toBe(true);
      expect(findUrl().attributes('value')).toBe(PROMETHEUS_URL);
    });

    it('should not show a footer block', () => {
      expect(wrapper.find('.footer-block').classes('d-none')).toBe(true);
    });
  });
});
