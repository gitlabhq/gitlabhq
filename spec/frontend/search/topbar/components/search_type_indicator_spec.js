import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_QUERY } from 'jest/search/mock_data';
import SearchTypeIndicator from '~/search/topbar/components/search_type_indicator.vue';

Vue.use(Vuex);

describe('SearchTypeIndicator', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    setQuery: jest.fn(),
    preloadStoredFrequentItems: jest.fn(),
  };

  const createComponent = (initialState = {}, defaultBranchName = '') => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMountExtended(SearchTypeIndicator, {
      store,
      propsData: { defaultBranchName },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findIndicator = (id) => wrapper.findAllByTestId(id);
  const findDocsLink = () => wrapper.findComponentByTestId('docs-link');
  const findSyntaxDocsLink = () => wrapper.findComponentByTestId('syntax-docs-link');

  describe.each`
    searchType    | repository  | showSearchTypeIndicator
    ${'advanced'} | ${'master'} | ${'advanced-enabled'}
    ${'advanced'} | ${'v0.1'}   | ${'advanced-disabled'}
    ${'zoekt'}    | ${'master'} | ${'zoekt-enabled'}
    ${'zoekt'}    | ${'v0.1'}   | ${'zoekt-disabled'}
  `(
    'search type indicator for $searchType',
    ({ searchType, repository, showSearchTypeIndicator }) => {
      beforeEach(() => {
        createComponent({
          query: { repository_ref: repository },
          searchType,
          defaultBranchName: 'master',
        });
      });
      it('renders correctly', () => {
        expect(findIndicator(showSearchTypeIndicator).exists()).toBe(true);
      });
    },
  );

  describe.each`
    searchType | repository  | showSearchTypeIndicator
    ${'basic'} | ${'master'} | ${true}
    ${'basic'} | ${'v0.1'}   | ${true}
  `(
    'search type indicator for $searchType and $repository',
    ({ searchType, repository, showSearchTypeIndicator }) => {
      beforeEach(() => {
        createComponent({
          query: { repository_ref: repository },
          searchType,
          defaultBranchName: 'master',
        });
      });
      it.each(['zoekt-enabled', 'zoekt-disabled', 'advanced-enabled', 'advanced-disabled'])(
        'renders correct indicator %s',
        () => {
          expect(findIndicator(searchType).exists()).toBe(showSearchTypeIndicator);
        },
      );
    },
  );

  describe.each`
    searchType    | docsLink
    ${'advanced'} | ${'/help/user/search/advanced_search'}
    ${'zoekt'}    | ${'/help/user/search/exact_code_search'}
  `('documentation link for $searchType', ({ searchType, docsLink }) => {
    beforeEach(() => {
      createComponent({
        query: { repository_ref: 'master' },
        searchType,
        defaultBranchName: 'master',
      });
    });
    it('has correct link', () => {
      expect(findDocsLink().attributes('href')).toBe(docsLink);
    });
  });

  describe.each`
    searchType    | syntaxdocsLink
    ${'advanced'} | ${'/help/user/search/advanced_search#use-the-advanced-search-syntax'}
    ${'zoekt'}    | ${'/help/user/search/exact_code_search#syntax'}
  `('Syntax documentation $searchType', ({ searchType, syntaxdocsLink }) => {
    beforeEach(() => {
      createComponent({
        query: { repository_ref: '000' },
        searchType,
        defaultBranchName: 'master',
      });
    });
    it('has correct link', () => {
      expect(findSyntaxDocsLink().attributes('href')).toBe(syntaxdocsLink);
    });
  });
});
