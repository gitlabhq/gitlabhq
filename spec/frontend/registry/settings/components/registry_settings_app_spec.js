import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import component from '~/registry/settings/components/registry_settings_app.vue';
import SettingsForm from '~/registry/settings/components/settings_form.vue';
import { createStore } from '~/registry/settings/store/';
import { SET_IS_DISABLED } from '~/registry/settings/store/mutation_types';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '~/registry/shared/constants';

describe('Registry Settings App', () => {
  let wrapper;
  let store;

  const findSettingsComponent = () => wrapper.find(SettingsForm);
  const findAlert = () => wrapper.find(GlAlert);

  const mountComponent = ({ dispatchMock = 'mockResolvedValue', isDisabled = false } = {}) => {
    store = createStore();
    store.commit(SET_IS_DISABLED, isDisabled);
    const dispatchSpy = jest.spyOn(store, 'dispatch');
    if (dispatchMock) {
      dispatchSpy[dispatchMock]();
    }
    wrapper = shallowMount(component, {
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it('call the store function to load the data on mount', () => {
    mountComponent();
    expect(store.dispatch).toHaveBeenCalledWith('fetchSettings');
  });

  it('show a toast if fetchSettings fails', () => {
    mountComponent({ dispatchMock: 'mockRejectedValue' });
    return wrapper.vm.$nextTick().then(() =>
      expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(FETCH_SETTINGS_ERROR_MESSAGE, {
        type: 'error',
      }),
    );
  });

  it('renders the setting form', () => {
    mountComponent();
    expect(findSettingsComponent().exists()).toBe(true);
  });

  describe('isDisabled', () => {
    beforeEach(() => {
      mountComponent({ isDisabled: true });
    });

    it('the form is hidden', () => {
      expect(findSettingsComponent().exists()).toBe(false);
    });

    it('shows an alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });
});
