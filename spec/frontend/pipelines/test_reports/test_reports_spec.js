import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { getJSONFixture } from 'helpers/fixtures';
import TestReports from '~/pipelines/components/test_reports/test_reports.vue';
import * as actions from '~/pipelines/stores/test_reports/actions';

describe('Test reports app', () => {
  let wrapper;
  let store;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const loadingSpinner = () => wrapper.find('.js-loading-spinner');
  const testsDetail = () => wrapper.find('.js-tests-detail');
  const noTestsToShow = () => wrapper.find('.js-no-tests-to-show');

  const createComponent = (state = {}) => {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        selectedSuite: {},
        testReports,
        ...state,
      },
      actions,
    });

    wrapper = shallowMount(TestReports, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => createComponent({ isLoading: true }));

    it('shows the loading spinner', () => {
      expect(noTestsToShow().exists()).toBe(false);
      expect(testsDetail().exists()).toBe(false);
      expect(loadingSpinner().exists()).toBe(true);
    });
  });

  describe('when the api returns no data', () => {
    beforeEach(() => createComponent({ testReports: {} }));

    it('displays that there are no tests to show', () => {
      const noTests = noTestsToShow();

      expect(noTests.exists()).toBe(true);
      expect(noTests.text()).toBe('There are no tests to show.');
    });
  });

  describe('when the api returns data', () => {
    beforeEach(() => createComponent());

    it('sets testReports and shows tests', () => {
      expect(wrapper.vm.testReports).toBeTruthy();
      expect(wrapper.vm.showTests).toBeTruthy();
    });
  });
});
