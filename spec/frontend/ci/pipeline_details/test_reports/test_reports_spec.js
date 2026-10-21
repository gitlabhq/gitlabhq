import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import testReports from 'test_fixtures/pipelines/test_report.json';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  getParameterValues,
  updateHistory,
  removeParams,
  setUrlParams,
} from '~/lib/utils/url_utility';
import EmptyState from '~/ci/pipeline_details/test_reports/empty_state.vue';
import TestReports from '~/ci/pipeline_details/test_reports/test_reports.vue';
import TestSummaryTable from '~/ci/pipeline_details/test_reports/test_summary_table.vue';
import * as getters from '~/ci/pipeline_details/stores/test_reports/getters';
import {
  SEARCH_SCOPE_SUITE,
  SEARCH_SCOPE_ALL,
} from '~/ci/pipeline_details/stores/test_reports/constants';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterValues: jest.fn().mockReturnValue([]),
  updateHistory: jest.fn().mockName('updateHistory'),
  removeParams: jest.fn().mockName('removeParams'),
  setUrlParams: jest.fn().mockName('setUrlParams'),
}));

describe('Test reports app', () => {
  let wrapper;
  let store;

  const loadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const testsDetail = () => wrapper.findByTestId('tests-detail');
  const emptyState = () => wrapper.findComponent(EmptyState);
  const testSummaryTable = () => wrapper.findComponent(TestSummaryTable);
  const searchInput = () => wrapper.findComponentByTestId('test-cases-search');
  const backButton = () => wrapper.findComponent('.js-back-button');

  const actionSpies = {
    fetchTestSuite: jest.fn(),
    fetchSummary: jest.fn(),
    fetchAllSuites: jest.fn(),
    setSelectedSuiteIndex: jest.fn(),
    removeSelectedSuiteIndex: jest.fn(),
    setPage: jest.fn(),
    setSearchTerm: jest.fn(),
    setSearchScope: jest.fn(),
  };

  beforeEach(() => {
    getParameterValues.mockReturnValue([]);
    Object.values(actionSpies).forEach((spy) => spy.mockClear());
  });

  const createComponent = ({ state = {}, glFeatures = {} } = {}) => {
    store = new Vuex.Store({
      modules: {
        testReports: {
          namespaced: true,
          state: {
            isLoading: false,
            selectedSuiteIndex: null,
            testReports,
            searchTerm: '',
            searchScope: SEARCH_SCOPE_SUITE,
            pageInfo: { page: 1, perPage: 20 },
            hasFetchedAllSuites: false,
            isLoadingAllSuites: false,
            ...state,
          },
          actions: actionSpies,
          getters: {
            ...getters,
          },
        },
      },
    });

    jest.spyOn(store, 'registerModule').mockReturnValue(null);

    wrapper = extendedWrapper(
      shallowMount(TestReports, {
        store,
        provide: {
          glFeatures: {
            junitTestReportSearch: true,
            ...glFeatures,
          },
        },
      }),
    );
  };

  describe('when component is created', () => {
    it('should call fetchSummary when pipeline has test report', () => {
      createComponent();

      expect(actionSpies.fetchSummary).toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => createComponent({ state: { isLoading: true } }));

    it('shows the loading spinner', () => {
      expect(emptyState().exists()).toBe(false);
      expect(testsDetail().exists()).toBe(false);
      expect(loadingSpinner().exists()).toBe(true);
    });
  });

  describe('when the api returns no data', () => {
    it('displays empty state component', () => {
      createComponent({ state: { testReports: {} } });

      expect(emptyState().exists()).toBe(true);
    });
  });

  describe('when the api returns data', () => {
    beforeEach(() => createComponent());

    it('sets testReports and shows tests', () => {
      expect(wrapper.vm.testReports).toEqual(expect.any(Object));
      expect(wrapper.vm.showTests).toBe(true);
    });

    it('shows tests details', () => {
      expect(testsDetail().exists()).toBe(true);
    });

    it('renders the search input', () => {
      expect(searchInput().exists()).toBe(true);
    });
  });

  describe('when feature flag is disabled', () => {
    beforeEach(() => {
      createComponent({ glFeatures: { junitTestReportSearch: false } });
    });

    it('does not render the search input', () => {
      expect(searchInput().exists()).toBe(false);
    });
  });

  describe('when a job name is provided as a query parameter', () => {
    beforeEach(() => {
      getParameterValues.mockReturnValue(['javascript']);
      createComponent();
    });

    it('shows tests details', () => {
      expect(testsDetail().exists()).toBe(true);
    });

    it('should call setSelectedSuiteIndex and fetchTestSuite', () => {
      expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalled();
      expect(actionSpies.fetchTestSuite).toHaveBeenCalled();
    });
  });

  describe('when a suite is clicked', () => {
    beforeEach(() => {
      document.title = 'Test reports';
      createComponent({
        state: { hasFullReport: true },
        getters: { getSelectedSuite: jest.fn().mockReturnValue({ name: 'test' }) },
      });
      testSummaryTable().vm.$emit('row-click', 0);
    });

    it('should call setSelectedSuiteIndex, fetchTestSuite and updateHistory', () => {
      expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalledWith(expect.anything(Object), 0);
      expect(actionSpies.fetchTestSuite).toHaveBeenCalledWith(expect.anything(Object), 0);
      expect(setUrlParams).toHaveBeenCalledWith({ job_name: undefined });
      expect(updateHistory).toHaveBeenCalledWith({
        replace: true,
        title: 'Test reports',
        url: undefined,
      });
    });

    it('resets search scope to suite and clears search term', () => {
      expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
        expect.anything(Object),
        SEARCH_SCOPE_SUITE,
      );
      expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(Object), '');
    });
  });

  describe('when clicking back to summary', () => {
    beforeEach(() => {
      document.title = 'Test reports';
      createComponent({
        state: {
          selectedSuiteIndex: 0,
          pageInfo: {
            page: 3,
            perPage: 20,
          },
        },
      });
      backButton().vm.$emit('click');
    });

    it('should call removeSelectedSuiteIndex, updateHistory and setPage', () => {
      expect(actionSpies.removeSelectedSuiteIndex).toHaveBeenCalled();
      expect(removeParams).toHaveBeenCalledWith(['job_name']);
      expect(updateHistory).toHaveBeenCalledWith({
        replace: true,
        title: 'Test reports',
        url: undefined,
      });
      expect(actionSpies.setPage).toHaveBeenCalledWith(expect.anything(Object), 1);
    });

    it('should reset search scope to all and clear search term', () => {
      expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
        expect.anything(Object),
        SEARCH_SCOPE_ALL,
      );
      expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(Object), '');
    });
  });

  describe('search functionality', () => {
    describe('when searching from summary view', () => {
      beforeEach(() => {
        createComponent();
        searchInput().vm.$emit('input', 'mytest');
      });

      it('calls setSearchTerm with the input value', () => {
        expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(), 'mytest');
      });

      it('calls setSearchScope with "all"', () => {
        expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
          expect.anything(),
          SEARCH_SCOPE_ALL,
        );
      });
    });

    describe('when searching from a drilled-in suite view', () => {
      beforeEach(() => {
        createComponent({ state: { selectedSuiteIndex: 0 } });
        searchInput().vm.$emit('input', 'mytest');
      });

      it('calls setSearchTerm with the input value', () => {
        expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(), 'mytest');
      });

      it('calls setSearchScope with "suite"', () => {
        expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
          expect.anything(),
          SEARCH_SCOPE_SUITE,
        );
      });
    });

    describe('when searching from a drilled-in suite view and search scope is already "all"', () => {
      beforeEach(() => {
        createComponent({
          state: {
            selectedSuiteIndex: 0,
            searchScope: SEARCH_SCOPE_ALL,
          },
        });
        searchInput().vm.$emit('input', 'mytest');
      });

      it('does not reset search scope to "suite"', () => {
        expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
          expect.anything(),
          SEARCH_SCOPE_ALL,
        );
      });
    });

    describe('when search term is empty', () => {
      describe('when in summary view', () => {
        beforeEach(() => {
          createComponent({ state: { searchTerm: 'existing' } });
          searchInput().vm.$emit('input', '');
        });

        it('calls setSearchTerm with an empty string', () => {
          expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(), '');
        });

        it('does not call setSearchScope', () => {
          expect(actionSpies.setSearchScope).not.toHaveBeenCalled();
        });
      });

      describe('when in drilled-in suite view', () => {
        beforeEach(() => {
          createComponent({ state: { selectedSuiteIndex: 0, searchTerm: 'existing' } });
          searchInput().vm.$emit('input', '');
        });

        it('calls setSearchTerm with an empty string', () => {
          expect(actionSpies.setSearchTerm).toHaveBeenCalledWith(expect.anything(), '');
        });

        it('resets search scope to suite', () => {
          expect(actionSpies.setSearchScope).toHaveBeenCalledWith(
            expect.anything(),
            SEARCH_SCOPE_SUITE,
          );
        });
      });
    });
  });
});
