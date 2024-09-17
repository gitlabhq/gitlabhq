import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ConfidentialityFilter from '~/search/sidebar/components/confidentiality_filter/index.vue';
import RadioFilter from '~/search/sidebar/components/shared/radio_filter.vue';

Vue.use(Vuex);

describe('ConfidentialityFilter', () => {
  let wrapper;

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = shallowMount(ConfidentialityFilter, {
      store,
    });
  };

  const findRadioFilter = () => wrapper.findComponent(RadioFilter);

  beforeEach(() => {
    createComponent();
  });

  it('renders the component', () => {
    expect(findRadioFilter().exists()).toBe(true);
  });
});
