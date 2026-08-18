import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import testReports from 'test_fixtures/pipelines/test_report.json';
import SummaryTable from '~/ci/pipeline_details/test_reports/test_summary_table.vue';
import * as getters from '~/ci/pipeline_details/stores/test_reports/getters';

Vue.use(Vuex);

describe('Test reports summary table', () => {
  let wrapper;
  let store;

  const allSuitesRows = () => wrapper.findAll('.js-suite-row');
  const noSuitesToShow = () => wrapper.find('.js-no-tests-suites');

  const defaultProps = {
    testReports,
  };

  const createComponent = (reports = null) => {
    store = new Vuex.Store({
      modules: {
        testReports: {
          namespaced: true,
          state: {
            testReports: reports || testReports,
          },
          getters,
        },
      },
    });

    wrapper = mount(SummaryTable, {
      provide: {
        blobPath: '/blob/path',
        summaryEndpoint: '/summary.json',
        suiteEndpoint: '/suite.json',
      },
      propsData: defaultProps,
      store,
    });
  };

  describe('when test reports are supplied', () => {
    beforeEach(() => createComponent());
    const findErrorIcon = () => wrapper.findComponent({ ref: 'suiteErrorIcon' });

    it('renders the correct number of rows', () => {
      expect(noSuitesToShow().exists()).toBe(false);
      expect(allSuitesRows()).toHaveLength(testReports.test_suites.length);
    });

    describe('when there is a suite error', () => {
      beforeEach(() => {
        createComponent({
          test_suites: [
            {
              ...testReports.test_suites[0],
              suite_error: 'Suite Error',
            },
          ],
        });
      });

      it('renders error icon', () => {
        expect(findErrorIcon().exists()).toBe(true);
        expect(findErrorIcon().attributes('title')).toEqual('Suite Error');
      });
    });

    describe('when there is not a suite error', () => {
      beforeEach(() => {
        createComponent({
          test_suites: [
            {
              ...testReports.test_suites[0],
              suite_error: null,
            },
          ],
        });
      });

      it('does not render error icon', () => {
        expect(findErrorIcon().exists()).toBe(false);
      });
    });
  });

  describe('sorting', () => {
    const suiteA = {
      ...testReports.test_suites[0],
      name: 'suite-a',
      failed_count: 1,
      error_count: 9,
      skipped_count: 2,
      success_count: 20,
      total_count: 32,
    };
    const suiteB = {
      ...testReports.test_suites[0],
      name: 'suite-b',
      failed_count: 5,
      error_count: 1,
      skipped_count: 8,
      success_count: 10,
      total_count: 24,
    };
    const suiteC = {
      ...testReports.test_suites[0],
      name: 'suite-c',
      failed_count: 3,
      error_count: 5,
      skipped_count: 4,
      success_count: 30,
      total_count: 42,
    };

    const findSortButton = (key) => wrapper.find(`[data-testid="sort-button-${key}"]`);
    const findSortIcon = (key) => wrapper.findComponent(`[data-testid="sort-icon-${key}"]`);
    const rowNames = () => allSuitesRows().wrappers.map((row) => row.find('.underline').text());

    beforeEach(() => {
      createComponent({ test_suites: [suiteA, suiteB, suiteC] });
    });

    it('defaults to sorting by failed tests, descending', () => {
      expect(findSortIcon('failed_count').props('name')).toBe('sort-highest');
      expect(findSortIcon('error_count').exists()).toBe(false);
      expect(rowNames()).toEqual(['suite-b', 'suite-c', 'suite-a']);
    });

    it('toggles the active column to ascending order on a second click', async () => {
      await findSortButton('failed_count').trigger('click');

      expect(findSortIcon('failed_count').props('name')).toBe('sort-lowest');
      expect(rowNames()).toEqual(['suite-a', 'suite-c', 'suite-b']);
    });

    it('switches the active column when a different header is clicked', async () => {
      await findSortButton('error_count').trigger('click');

      expect(findSortIcon('failed_count').exists()).toBe(false);
      expect(findSortIcon('error_count').props('name')).toBe('sort-highest');
      expect(rowNames()).toEqual(['suite-a', 'suite-c', 'suite-b']);
    });

    it('toggles the newly active column independently of the previous one', async () => {
      await findSortButton('error_count').trigger('click');
      await findSortButton('error_count').trigger('click');

      expect(findSortIcon('error_count').props('name')).toBe('sort-lowest');
      expect(rowNames()).toEqual(['suite-b', 'suite-c', 'suite-a']);
    });

    it('emits the suite original index on row click, not the display position', async () => {
      await findSortButton('error_count').trigger('click');
      // displayed order is now [suite-a, suite-c, suite-b] by error_count descending
      // suite-c is shown second (display index 1) but its original index in test_suites is 2

      await allSuitesRows().at(1).trigger('click');

      expect(wrapper.emitted('row-click')[0]).toEqual([2]);
    });
  });

  describe('when there are no test suites', () => {
    beforeEach(() => {
      createComponent({ test_suites: [] });
    });

    it('displays the no suites to show message', () => {
      expect(noSuitesToShow().exists()).toBe(true);
    });
  });
});
