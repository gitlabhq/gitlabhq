import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import { SEARCH_TYPE_ADVANCED } from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('GlobalSearch BlobsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'blobs',
  };

  const createComponent = () => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        searchType: SEARCH_TYPE_ADVANCED,
      },
      getters: defaultGetters,
    });

    wrapper = shallowMount(BlobsFilters, {
      store,
    });
  };

  const findLanguageFilter = () => wrapper.findComponent(LanguageFilter);
  const findArchivedFilter = () => wrapper.findComponent(ArchivedFilter);

  beforeEach(() => {
    createComponent();
  });

  it('renders LanguageFilter', () => {
    expect(findLanguageFilter().exists()).toBe(true);
  });

  it('renders ArchivedFilter', () => {
    expect(findArchivedFilter().exists()).toBe(true);
  });
});
