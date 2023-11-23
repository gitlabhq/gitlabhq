import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import testReports from 'test_fixtures/pipelines/test_report.json';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { getParameterValues } from '~/lib/utils/url_utility';
import EmptyState from '~/ci/pipeline_details/test_reports/empty_state.vue';
import TestReports from '~/ci/pipeline_details/test_reports/test_reports.vue';
import TestSummary from '~/ci/pipeline_details/test_reports/test_summary.vue';
import TestSummaryTable from '~/ci/pipeline_details/test_reports/test_summary_table.vue';
import * as getters from '~/ci/pipeline_details/stores/test_reports/getters';

Vue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterValues: jest.fn().mockReturnValue([]),
}));

describe('Test reports app', () => {
  let wrapper;
  let store;

  const loadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const testsDetail = () => wrapper.findByTestId('tests-detail');
  const emptyState = () => wrapper.findComponent(EmptyState);
  const testSummary = () => wrapper.findComponent(TestSummary);
  const testSummaryTable = () => wrapper.findComponent(TestSummaryTable);

  const actionSpies = {
    fetchTestSuite: jest.fn(),
    fetchSummary: jest.fn(),
    setSelectedSuiteIndex: jest.fn(),
    removeSelectedSuiteIndex: jest.fn(),
  };

  const createComponent = ({ state = {} } = {}) => {
    store = new Vuex.Store({
      modules: {
        testReports: {
          namespaced: true,
          state: {
            isLoading: false,
            selectedSuiteIndex: null,
            testReports,
            ...state,
          },
          actions: actionSpies,
          getters,
        },
      },
    });

    jest.spyOn(store, 'registerModule').mockReturnValue(null);

    wrapper = extendedWrapper(
      shallowMount(TestReports, {
        provide: {
          blobPath: '/blob/path',
          summaryEndpoint: '/summary.json',
          suiteEndpoint: '/suite.json',
        },
        store,
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
      createComponent({ state: { hasFullReport: true } });
      testSummaryTable().vm.$emit('row-click', 0);
    });

    it('should call setSelectedSuiteIndex and fetchTestSuite', () => {
      expect(actionSpies.setSelectedSuiteIndex).toHaveBeenCalled();
      expect(actionSpies.fetchTestSuite).toHaveBeenCalled();
    });
  });

  describe('when clicking back to summary', () => {
    beforeEach(() => {
      createComponent({ state: { selectedSuiteIndex: 0 } });
      testSummary().vm.$emit('on-back-click');
    });

    it('should call removeSelectedSuiteIndex', () => {
      expect(actionSpies.removeSelectedSuiteIndex).toHaveBeenCalled();
    });
  });
});
