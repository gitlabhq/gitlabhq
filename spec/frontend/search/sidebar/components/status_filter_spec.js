import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import RadioFilter from '~/search/sidebar/components/radio_filter.vue';
import StatusFilter from '~/search/sidebar/components/status_filter.vue';

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
  const findHR = () => wrapper.findComponent('hr');

  describe('old sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: false });
    });

    it('renders the component', () => {
      expect(findRadioFilter().exists()).toBe(true);
    });

    it('renders the divider', () => {
      expect(findHR().exists()).toBe(true);
    });
  });

  describe('new sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: true });
    });

    it('renders the component', () => {
      expect(findRadioFilter().exists()).toBe(true);
    });

    it("doesn't render the divider", () => {
      expect(findHR().exists()).toBe(false);
    });
  });
});
