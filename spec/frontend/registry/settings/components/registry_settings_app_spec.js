import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from '~/registry/settings/components/registry_settings_app.vue';
import { createStore } from '~/registry/settings/stores/';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Registry List', () => {
  let wrapper;
  let store;

  const helpPagePath = 'foo';
  const findHelpLink = () => wrapper.find({ ref: 'help-link' }).find('a');

  const mountComponent = (options = {}) =>
    shallowMount(component, {
      sync: false,
      store,
      ...options,
    });

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialState', { helpPagePath });
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders an help link dependant on the helphPagePath', () => {
    expect(findHelpLink().attributes('href')).toBe(helpPagePath);
  });
});
