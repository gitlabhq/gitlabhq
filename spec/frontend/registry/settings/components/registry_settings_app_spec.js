import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import component from '~/registry/settings/components/registry_settings_app.vue';
import SettingsForm from '~/registry/settings/components/settings_form.vue';
import { createStore } from '~/registry/settings/store/';
import { SET_SETTINGS, SET_INITIAL_STATE } from '~/registry/settings/store/mutation_types';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '~/registry/shared/constants';
import { stringifiedFormOptions } from '../../shared/mock_data';

describe('Registry Settings App', () => {
  let wrapper;
  let store;

  const findSettingsComponent = () => wrapper.find(SettingsForm);
  const findAlert = () => wrapper.find(GlAlert);

  const mountComponent = ({ dispatchMock = 'mockResolvedValue' } = {}) => {
    const dispatchSpy = jest.spyOn(store, 'dispatch');
    dispatchSpy[dispatchMock]();

    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    store.commit(SET_SETTINGS, { foo: 'bar' });
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('call the store function to load the data on mount', () => {
    mountComponent();
    expect(store.dispatch).toHaveBeenCalledWith('fetchSettings');
  });

  it('renders the setting form', () => {
    store.commit(SET_SETTINGS, { foo: 'bar' });
    mountComponent();
    expect(findSettingsComponent().exists()).toBe(true);
  });

  describe('the form is disabled', () => {
    beforeEach(() => {
      store.commit(SET_SETTINGS, undefined);
      mountComponent();
    });

    it('the form is hidden', () => {
      expect(findSettingsComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      const text = findAlert().text();
      expect(text).toContain(
        'The Container Registry tag expiration and retention policies for this project have not been enabled.',
      );
      expect(text).toContain('Please contact your administrator.');
    });

    describe('an admin is visiting the page', () => {
      beforeEach(() => {
        store.commit(SET_INITIAL_STATE, {
          ...stringifiedFormOptions,
          isAdmin: true,
          adminSettingsPath: 'foo',
        });
      });

      it('shows the admin part of the alert message', () => {
        const sprintf = findAlert().find(GlSprintf);
        expect(sprintf.text()).toBe('administration settings');
        expect(sprintf.find(GlLink).attributes('href')).toBe('foo');
      });
    });
  });

  describe('fetchSettingsError', () => {
    beforeEach(() => {
      mountComponent({ dispatchMock: 'mockRejectedValue' });
    });

    it('the form is hidden', () => {
      expect(findSettingsComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      expect(findAlert().html()).toContain(FETCH_SETTINGS_ERROR_MESSAGE);
    });
  });
});
