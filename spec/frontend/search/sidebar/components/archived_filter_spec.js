import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { GlFormCheckboxGroup } from '@gitlab/ui';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';

import { archivedFilterData } from '~/search/sidebar/components/archived_filter/data';

Vue.use(Vuex);

describe('ArchivedFilter', () => {
  let wrapper;

  const createComponent = (state) => {
    const store = new Vuex.Store({
      state,
    });

    wrapper = shallowMount(ArchivedFilter, {
      store,
    });
  };

  const findCheckboxFilter = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findH5 = () => wrapper.findComponent('h5');

  describe('old sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: false });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it('renders the divider', () => {
      expect(findH5().exists()).toBe(true);
      expect(findH5().text()).toBe(archivedFilterData.headerLabel);
    });
  });

  describe('new sidebar', () => {
    beforeEach(() => {
      createComponent({ useNewNavigation: true });
    });

    it('renders the component', () => {
      expect(findCheckboxFilter().exists()).toBe(true);
    });

    it("doesn't render the divider", () => {
      expect(findH5().exists()).toBe(true);
      expect(findH5().text()).toBe(archivedFilterData.headerLabel);
    });
  });
});
