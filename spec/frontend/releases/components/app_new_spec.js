import Vue from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import ReleaseNewApp from '~/releases/components/app_new.vue';

Vue.use(Vuex);

describe('Release new component', () => {
  let wrapper;

  const factory = () => {
    const store = new Vuex.Store();
    wrapper = mount(ReleaseNewApp, { store });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the app', () => {
    factory();

    expect(wrapper.exists()).toBe(true);
  });
});
