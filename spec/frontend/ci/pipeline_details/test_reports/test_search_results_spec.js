import { GlLoadingIcon, GlPagination, GlFriendlyWrap, GlLink } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TestSearchResults from '~/ci/pipeline_details/test_reports/test_search_results.vue';
import TestCaseDetails from '~/ci/pipeline_details/test_reports/test_case_details.vue';

Vue.use(Vuex);

describe('TestSearchResults', () => {
  let wrapper;
  let store;

  const mockTestCases = [
    {
      name: 'Test 1',
      classname: 'spec.test1',
      file: './spec/test1.js',
      filePath: '/blob/path/spec/test1.js',
      suiteName: 'jest unit',
      status: 'success',
      icon: 'status_success',
      formattedTime: '1.50s',
    },
    {
      name: 'Test 2',
      classname: 'spec.test2',
      file: './spec/test2.js',
      filePath: '/blob/path/spec/test2.js',
      suiteName: 'rspec unit',
      status: 'failed',
      icon: 'status_failed',
      formattedTime: '2.10s',
    },
  ];

  const actionSpies = {
    setPage: jest.fn(),
  };

  const createComponent = ({
    isLoadingAllSuites = false,
    searchResults = mockTestCases,
    page = 1,
    perPage = 20,
    mountFn = shallowMountExtended,
  } = {}) => {
    store = new Vuex.Store({
      modules: {
        testReports: {
          namespaced: true,
          state: {
            isLoadingAllSuites,
            pageInfo: {
              page,
              perPage,
            },
          },
          getters: {
            getSearchResults: () => searchResults,
            getSearchResultsCount: () => searchResults.length,
          },
          actions: actionSpies,
        },
      },
    });

    wrapper = mountFn(TestSearchResults, {
      store,
      stubs: {
        GlTable: false,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNoResultsMessage = () => wrapper.findByTestId('no-search-results');
  const findTable = () => wrapper.findByTestId('test-search-results-table');
  const findPagination = () => wrapper.findComponent(GlPagination);

  describe('when loading all suites', () => {
    beforeEach(() => {
      createComponent({ isLoadingAllSuites: true });
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findNoResultsMessage().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when search has no results', () => {
    beforeEach(() => {
      createComponent({ searchResults: [] });
    });

    it('renders empty message and no table', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findNoResultsMessage().exists()).toBe(true);
      expect(findNoResultsMessage().text()).toBe('No test cases match your search.');
      expect(findTable().exists()).toBe(false);
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('when search has results', () => {
    beforeEach(() => {
      createComponent({ searchResults: mockTestCases });
    });

    it('renders table with results', () => {
      expect(findTable().exists()).toBe(true);
      expect(findNoResultsMessage().exists()).toBe(false);
    });

    it('renders pagination component', () => {
      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props('totalItems')).toBe(mockTestCases.length);
      expect(findPagination().props('perPage')).toBe(20);
    });

    describe('when page is changed', () => {
      beforeEach(() => {
        findPagination().vm.$emit('input', 2);
      });

      it('dispatches setPage', () => {
        expect(actionSpies.setPage).toHaveBeenCalledWith(expect.any(Object), 2);
      });
    });
  });

  describe('table contents', () => {
    beforeEach(() => {
      createComponent({
        searchResults: mockTestCases,
        mountFn: mountExtended,
      });
    });

    it('renders the friendly-wrapped text for suiteName, classname, and name', () => {
      const friendlyWraps = wrapper.findAllComponents(GlFriendlyWrap);
      const texts = friendlyWraps.wrappers.map((w) => w.text());

      expect(texts).toContain('jest unit');
      expect(texts).toContain('spec.test1');
      expect(texts).toContain('Test 1');
    });

    it('renders file link and copy button', () => {
      const fileLink = wrapper.findComponent(GlLink);
      const copyButton = wrapper.findComponent(SimpleCopyButton);

      expect(fileLink.attributes('href')).toBe('/blob/path/spec/test1.js');
      expect(copyButton.props('text')).toBe('./spec/test1.js');
    });

    it('renders test case details modal component', () => {
      const detailsModals = wrapper.findAllComponents(TestCaseDetails);

      expect(detailsModals).toHaveLength(mockTestCases.length);
      expect(detailsModals.at(0).props('modalId')).toBe('test-search-result-details-0');
      expect(detailsModals.at(0).props('testCase')).toEqual(mockTestCases[0]);
    });

    it('renders ci-icon component for status', () => {
      const icons = wrapper.findAllComponents(CiIcon);

      expect(icons).toHaveLength(mockTestCases.length);
      expect(icons.at(0).props('status')).toEqual(mockTestCases[0]);
    });
  });
});
