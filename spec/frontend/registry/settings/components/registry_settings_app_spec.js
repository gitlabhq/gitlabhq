import { shallowMount } from '@vue/test-utils';
import component from '~/registry/settings/components/registry_settings_app.vue';
import { createStore } from '~/registry/settings/store/';
import { FETCH_SETTINGS_ERROR_MESSAGE } from '~/registry/settings/constants';

describe('Registry Settings App', () => {
  let wrapper;
  let store;

  const findSettingsComponent = () => wrapper.find({ ref: 'settings-form' });

  const mountComponent = ({ dispatchMock } = {}) => {
    store = createStore();
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
    mountComponent({ dispatchMock: 'mockResolvedValue' });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('call the store function to load the data on mount', () => {
    mountComponent({ dispatchMock: 'mockResolvedValue' });
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
    mountComponent({ dispatchMock: 'mockResolvedValue' });
    expect(findSettingsComponent().exists()).toBe(true);
  });
});
