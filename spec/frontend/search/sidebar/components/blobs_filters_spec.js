import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import {
  SEARCH_TYPE_ZOEKT,
  SEARCH_TYPE_ADVANCED,
  SEARCH_TYPE_BASIC,
} from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('GlobalSearch BlobsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'blobs',
    showArchived: () => true,
  };

  const createComponent = (initialState = { searchType: SEARCH_TYPE_ADVANCED }) => {
    const store = new Vuex.Store({
      state: {
        urlQuery: MOCK_QUERY,
        ...initialState,
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

  describe.each`
    searchType              | isShown
    ${SEARCH_TYPE_BASIC}    | ${false}
    ${SEARCH_TYPE_ADVANCED} | ${true}
    ${SEARCH_TYPE_ZOEKT}    | ${false}
  `('sidebar blobs language filter:', ({ searchType, isShown }) => {
    beforeEach(() => {
      createComponent({ searchType });
    });

    it(`does ${isShown ? '' : 'not '}render LanguageFilter when search_type ${searchType}`, () => {
      expect(findLanguageFilter().exists()).toBe(isShown);
    });
  });

  it('renders ArchivedFilter', () => {
    expect(findArchivedFilter().exists()).toBe(true);
  });

  describe('ShowArchived getter', () => {
    beforeEach(() => {
      defaultGetters.showArchived = () => false;
      createComponent();
    });

    it('hides archived filter', () => {
      expect(findArchivedFilter().exists()).toBe(false);
    });
  });
});
