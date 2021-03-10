import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import FilteredSearch from '~/boards/components/filtered_search.vue';
import { createStore } from '~/boards/stores';
import * as commonUtils from '~/lib/utils/common_utils';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('FilteredSearch', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = shallowMount(FilteredSearch, {
      localVue,
      propsData: { search: '' },
      store,
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    // this needed for actions call for performSearch
    window.gon = { features: {} };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      store = createStore();

      jest.spyOn(store, 'dispatch');

      createComponent();
    });

    it('finds FilteredSearch', () => {
      expect(wrapper.find(FilteredSearchBarRoot).exists()).toBe(true);
    });

    describe('when onFilter is emitted', () => {
      it('calls performSearch', () => {
        wrapper.find(FilteredSearchBarRoot).vm.$emit('onFilter', [{ value: { data: '' } }]);

        expect(store.dispatch).toHaveBeenCalledWith('performSearch');
      });

      it('calls historyPushState', () => {
        commonUtils.historyPushState = jest.fn();
        wrapper
          .find(FilteredSearchBarRoot)
          .vm.$emit('onFilter', [{ value: { data: 'searchQuery' } }]);

        expect(commonUtils.historyPushState).toHaveBeenCalledWith(
          'http://test.host/?search=searchQuery',
        );
      });
    });
  });
});
