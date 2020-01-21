import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from '~/registry/settings/components/registry_settings_app.vue';
import { createStore } from '~/registry/settings/store/';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Registry Settings App', () => {
  let wrapper;
  let store;
  let fetchSpy;

  const findSettingsComponent = () => wrapper.find({ ref: 'settings-form' });
  const findLoadingComponent = () => wrapper.find({ ref: 'loading-icon' });

  const mountComponent = (options = {}) => {
    fetchSpy = jest.fn();
    wrapper = shallowMount(component, {
      store,
      methods: {
        fetchSettings: fetchSpy,
      },
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('call the store function to load the data on mount', () => {
    expect(fetchSpy).toHaveBeenCalled();
  });

  it('renders a loader if isLoading is true', () => {
    store.dispatch('toggleLoading');
    return wrapper.vm.$nextTick().then(() => {
      expect(findLoadingComponent().exists()).toBe(true);
      expect(findSettingsComponent().exists()).toBe(false);
    });
  });
  it('renders the setting form', () => {
    expect(findSettingsComponent().exists()).toBe(true);
  });
});
