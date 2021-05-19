import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { getJSONFixture } from 'helpers/fixtures';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/pipelines/components/test_reports/empty_state.vue';
import TestReports from '~/pipelines/components/test_reports/test_reports.vue';
import TestSummary from '~/pipelines/components/test_reports/test_summary.vue';
import TestSummaryTable from '~/pipelines/components/test_reports/test_summary_table.vue';
import * as getters from '~/pipelines/stores/test_reports/getters';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Test reports app', () => {
  let wrapper;
  let store;

  const testReports = getJSONFixture('pipelines/test_report.json');

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
      state: {
        isLoading: false,
        selectedSuiteIndex: null,
        testReports,
        ...state,
      },
      actions: actionSpies,
      getters,
    });

    wrapper = extendedWrapper(
      shallowMount(TestReports, {
        store,
        localVue,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
      expect(wrapper.vm.testReports).toBeTruthy();
      expect(wrapper.vm.showTests).toBeTruthy();
    });

    it('shows tests details', () => {
      expect(testsDetail().exists()).toBe(true);
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
