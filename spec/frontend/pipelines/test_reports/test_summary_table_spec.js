import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
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

    it('renders the correct number of rows', () => {
      expect(noSuitesToShow().exists()).toBe(false);
      expect(allSuitesRows().length).toBe(testReports.test_suites.length);
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
