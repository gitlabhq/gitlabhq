import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { getJSONFixture } from 'helpers/fixtures';
import SuiteTable from '~/pipelines/components/test_reports/test_suite_table.vue';
import * as getters from '~/pipelines/stores/test_reports/getters';
import { TestStatus } from '~/pipelines/constants';
import skippedTestCases from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Test reports suite table', () => {
  let wrapper;
  let store;

  const {
    test_suites: [testSuite],
  } = getJSONFixture('pipelines/test_report.json');

  testSuite.test_cases = [...testSuite.test_cases, ...skippedTestCases];
  const testCases = testSuite.test_cases;

  const noCasesMessage = () => wrapper.find('.js-no-test-cases');
  const allCaseRows = () => wrapper.findAll('.js-case-row');
  const findCaseRowAtIndex = index => wrapper.findAll('.js-case-row').at(index);
  const allCaseNames = () =>
    wrapper.findAll('[data-testid="caseName"]').wrappers.map(el => el.attributes('text'));
  const findIconForRow = (row, status) => row.find(`.ci-status-icon-${status}`);

  const createComponent = (suite = testSuite) => {
    store = new Vuex.Store({
      state: {
        testReports: {
          test_suites: [suite],
        },
        selectedSuiteIndex: 0,
      },
      getters,
    });

    wrapper = shallowMount(SuiteTable, {
      store,
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('should not render', () => {
    beforeEach(() => createComponent([]));

    it('a table when there are no test cases', () => {
      expect(noCasesMessage().exists()).toBe(true);
    });
  });

  describe('when a test suite is supplied', () => {
    beforeEach(() => createComponent());

    it('renders the correct number of rows', () => {
      expect(allCaseRows().length).toBe(testCases.length);
    });

    it('renders the failed tests first, skipped tests next, then successful tests', () => {
      const expectedCaseOrder = [
        ...testCases.filter(x => x.status === TestStatus.FAILED),
        ...testCases.filter(x => x.status === TestStatus.SKIPPED),
        ...testCases.filter(x => x.status === TestStatus.SUCCESS),
      ].map(x => x.name);

      expect(allCaseNames()).toEqual(expectedCaseOrder);
    });

    it('renders the correct icon for each status', () => {
      const failedTest = testCases.findIndex(x => x.status === TestStatus.FAILED);
      const skippedTest = testCases.findIndex(x => x.status === TestStatus.SKIPPED);
      const successTest = testCases.findIndex(x => x.status === TestStatus.SUCCESS);

      const failedRow = findCaseRowAtIndex(failedTest);
      const skippedRow = findCaseRowAtIndex(skippedTest);
      const successRow = findCaseRowAtIndex(successTest);

      expect(findIconForRow(failedRow, TestStatus.FAILED).exists()).toBe(true);
      expect(findIconForRow(skippedRow, TestStatus.SKIPPED).exists()).toBe(true);
      expect(findIconForRow(successRow, TestStatus.SUCCESS).exists()).toBe(true);
    });
  });
});
