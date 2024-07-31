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

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const createComponent = (initialState = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(SearchTypeIndicator, {
      store,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findIndicator = (id) => wrapper.findAllByTestId(id);
  const findDocsLink = () => wrapper.findComponentByTestId('docs-link');
  const findSyntaxDocsLink = () => wrapper.findComponentByTestId('syntax-docs-link');

  // searchType and search level params cobination in this test reflects
  // all possible combinations

  describe.each`
    searchType    | searchLevel  | repository  | scope       | showSearchTypeIndicator
    ${'advanced'} | ${'project'} | ${'master'} | ${'blobs'}  | ${'advanced-enabled'}
    ${'advanced'} | ${'project'} | ${'v0.1'}   | ${'blobs'}  | ${'advanced-disabled'}
    ${'advanced'} | ${'group'}   | ${'master'} | ${'blobs'}  | ${'advanced-enabled'}
    ${'advanced'} | ${'global'}  | ${'master'} | ${'blobs'}  | ${'advanced-enabled'}
    ${'zoekt'}    | ${'project'} | ${'master'} | ${'blobs'}  | ${'zoekt-enabled'}
    ${'zoekt'}    | ${'project'} | ${'v0.1'}   | ${'blobs'}  | ${'zoekt-disabled'}
    ${'zoekt'}    | ${'group'}   | ${'master'} | ${'blobs'}  | ${'zoekt-enabled'}
    ${'advanced'} | ${'project'} | ${'master'} | ${'issues'} | ${'advanced-enabled'}
    ${'advanced'} | ${'project'} | ${'v0.1'}   | ${'issues'} | ${'advanced-enabled'}
    ${'advanced'} | ${'group'}   | ${'master'} | ${'issues'} | ${'advanced-enabled'}
    ${'advanced'} | ${'global'}  | ${'master'} | ${'issues'} | ${'advanced-enabled'}
    ${'zoekt'}    | ${'project'} | ${'master'} | ${'issues'} | ${'advanced-enabled'}
    ${'zoekt'}    | ${'project'} | ${'v0.1'}   | ${'issues'} | ${'advanced-enabled'}
    ${'zoekt'}    | ${'group'}   | ${'master'} | ${'issues'} | ${'advanced-enabled'}
  `(
    'search type indicator for $searchType $searchLevel $scope',
    ({ searchType, repository, showSearchTypeIndicator, scope, searchLevel }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({
          query: { repository_ref: repository, scope },
          searchType,
          searchLevel,
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
          query: { repository_ref: repository, scope: 'blobs' },
          searchType,
          searchLevel: 'project',
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
      getterSpies.currentScope = jest.fn(() => 'blobs');
      createComponent({
        query: { repository_ref: 'master', scope: 'blobs' },
        searchType,
        searchLevel: 'project',
        defaultBranchName: 'master',
      });
    });
    it('has correct link', () => {
      expect(findDocsLink().attributes('href')).toBe(docsLink);
    });
  });

  describe.each`
    searchType    | syntaxdocsLink
    ${'advanced'} | ${'/help/user/search/advanced_search#syntax'}
    ${'zoekt'}    | ${'/help/user/search/exact_code_search#syntax'}
  `('Syntax documentation $searchType', ({ searchType, syntaxdocsLink }) => {
    beforeEach(() => {
      createComponent({
        query: { repository_ref: '000', scope: 'blobs' },
        searchType,
        searchLevel: 'project',
        defaultBranchName: 'master',
      });
    });
    it('has correct link', () => {
      expect(findSyntaxDocsLink().attributes('href')).toBe(syntaxdocsLink);
    });
  });

  describe('Indicator is not using url query as source of truth', () => {
    beforeEach(() => {
      createComponent({
        query: { repository_ref: 'master', scope: 'project' },
        searchType: 'zoekt',
        searchLevel: 'project',
        defaultBranchName: 'master',
      });
    });
    it('has correct link', () => {
      expect(findIndicator('zoekt-enabled').exists()).toBe(true);
    });
  });
});
