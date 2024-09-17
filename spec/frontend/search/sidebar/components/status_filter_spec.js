import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import RadioFilter from '~/search/sidebar/components/shared/radio_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter/index.vue';

Vue.use(Vuex);

describe('StatusFilter', () => {
  let wrapper;

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = shallowMount(StatusFilter, {
      store,
    });
  };

  const findRadioFilter = () => wrapper.findComponent(RadioFilter);

  it('renders the component', () => {
    createComponent();

    expect(findRadioFilter().exists()).toBe(true);
  });
});
