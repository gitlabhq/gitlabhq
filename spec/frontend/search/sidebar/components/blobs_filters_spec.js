import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import BlobsFilters from '~/search/sidebar/components/blobs_filters.vue';
import LanguageFilter from '~/search/sidebar/components/language_filter/index.vue';
import ArchivedFilter from '~/search/sidebar/components/archived_filter/index.vue';
import ForksFilter from '~/search/sidebar/components/forks_filter/index.vue';

Vue.use(Vuex);

describe('GlobalSearch BlobsFilters', () => {
  let wrapper;

  const defaultGetters = {
    currentScope: () => 'blobs',
    hasMissingProjectContext: () => true,
  };

  const createComponent = (initialState = { searchType: 'advanced' }) => {
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
  const findForksFilter = () => wrapper.findComponent(ForksFilter);

  beforeEach(() => {
    createComponent();
  });

  describe.each`
    searchType    | isShown
    ${'basic'}    | ${false}
    ${'advanced'} | ${true}
    ${'zoekt'}    | ${false}
  `('sidebar blobs language filter:', ({ searchType, isShown }) => {
    beforeEach(() => {
      createComponent({ searchType });
    });

    it(`does ${isShown ? '' : 'not '}render LanguageFilter when search_type ${searchType}`, () => {
      expect(findLanguageFilter().exists()).toBe(isShown);
    });
  });

  describe.each`
    searchType    | hasProjectContent | isShown
    ${'basic'}    | ${true}           | ${false}
    ${'basic'}    | ${false}          | ${false}
    ${'advanced'} | ${true}           | ${false}
    ${'advanced'} | ${false}          | ${false}
    ${'zoekt'}    | ${true}           | ${true}
    ${'zoekt'}    | ${false}          | ${false}
  `('sidebar blobs fork filter:', ({ searchType, hasProjectContent, isShown }) => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => hasProjectContent;
      createComponent({ searchType });
    });

    it(`does ${isShown ? '' : 'not '}render ForksFilter when search_type ${searchType} and hasProjectContent ${hasProjectContent}}`, () => {
      expect(findForksFilter().exists()).toBe(isShown);
    });
  });

  describe.each`
    searchType    | hasProjectContent | isShown
    ${'basic'}    | ${true}           | ${true}
    ${'basic'}    | ${false}          | ${false}
    ${'advanced'} | ${true}           | ${true}
    ${'advanced'} | ${false}          | ${false}
    ${'zoekt'}    | ${true}           | ${true}
    ${'zoekt'}    | ${false}          | ${false}
  `('sidebar blobs archived filter:', ({ searchType, hasProjectContent, isShown }) => {
    beforeEach(() => {
      defaultGetters.hasMissingProjectContext = () => hasProjectContent;
      createComponent({ searchType });
    });

    it(`does ${isShown ? '' : 'not '}render ArchivedFilter when search_type ${searchType} and hasProjectContent ${hasProjectContent}}`, () => {
      expect(findArchivedFilter().exists()).toBe(isShown);
    });
  });
});
