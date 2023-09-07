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
      expect(allSuitesRows().length).toBe(testReports.test_suites.length);
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

  describe('when there are no test suites', () => {
    beforeEach(() => {
      createComponent({ test_suites: [] });
    });

    it('displays the no suites to show message', () => {
      expect(noSuitesToShow().exists()).toBe(true);
    });
  });
});
