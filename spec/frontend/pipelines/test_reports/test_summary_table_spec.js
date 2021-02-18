import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { getJSONFixture } from 'helpers/fixtures';
import SummaryTable from '~/pipelines/components/test_reports/test_summary_table.vue';
import * as getters from '~/pipelines/stores/test_reports/getters';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Test reports summary table', () => {
  let wrapper;
  let store;

  const testReports = getJSONFixture('pipelines/test_report.json');

  const allSuitesRows = () => wrapper.findAll('.js-suite-row');
  const noSuitesToShow = () => wrapper.find('.js-no-tests-suites');

  const defaultProps = {
    testReports,
  };

  const createComponent = (reports = null) => {
    store = new Vuex.Store({
      state: {
        testReports: reports || testReports,
      },
      getters,
    });

    wrapper = mount(SummaryTable, {
      propsData: defaultProps,
      store,
      localVue,
    });
  };

  describe('when test reports are supplied', () => {
    beforeEach(() => createComponent());
    const findErrorIcon = () => wrapper.find({ ref: 'suiteErrorIcon' });

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
