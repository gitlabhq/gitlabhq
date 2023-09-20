import { mount } from '@vue/test-utils';
import testReports from 'test_fixtures/pipelines/test_report.json';
import Summary from '~/ci/pipeline_details/test_reports/test_summary.vue';
import { formattedTime } from '~/ci/pipeline_details/stores/test_reports/utils';

describe('Test reports summary', () => {
  let wrapper;

  const {
    test_suites: [testSuite],
  } = testReports;

  const backButton = () => wrapper.find('.js-back-button');
  const totalTests = () => wrapper.find('.js-total-tests');
  const failedTests = () => wrapper.find('.js-failed-tests');
  const erroredTests = () => wrapper.find('.js-errored-tests');
  const successRate = () => wrapper.find('.js-success-rate');
  const duration = () => wrapper.find('.js-duration');

  const defaultProps = {
    report: testSuite,
    showBack: false,
  };

  const createComponent = (props) => {
    wrapper = mount(Summary, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('should not render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('a back button by default', () => {
      expect(backButton().exists()).toBe(false);
    });
  });

  describe('should render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('a back button and emit on-back-click event', () => {
      createComponent({
        showBack: true,
      });

      expect(backButton().exists()).toBe(true);
    });
  });

  describe('when a report is supplied', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the correct total', () => {
      expect(totalTests().text()).toBe('4 tests');
    });

    it('displays the correct failure count', () => {
      expect(failedTests().text()).toBe('2 failures');
    });

    it('displays the correct error count', () => {
      expect(erroredTests().text()).toBe('0 errors');
    });

    it('calculates and displays percentages correctly', () => {
      expect(successRate().text()).toBe('50% success rate');
    });

    it('displays the correctly formatted duration', () => {
      expect(duration().text()).toBe(formattedTime(testSuite.total_time));
    });
  });

  describe('success percentage calculation', () => {
    it.each`
      name                                     | successCount | totalCount | skippedCount | result
      ${'displays 0 when there are no tests'}  | ${0}         | ${0}       | ${0}         | ${'0'}
      ${'displays whole number when possible'} | ${10}        | ${50}      | ${0}         | ${'20'}
      ${'excludes skipped tests from total'}   | ${10}        | ${50}      | ${5}         | ${'22.22'}
      ${'rounds to 0.01'}                      | ${1}         | ${16604}   | ${0}         | ${'0.01'}
      ${'correctly rounds to 50'}              | ${8302}      | ${16604}   | ${0}         | ${'50'}
      ${'rounds down for large close numbers'} | ${16603}     | ${16604}   | ${0}         | ${'99.99'}
      ${'correctly displays 100'}              | ${16604}     | ${16604}   | ${0}         | ${'100'}
    `('$name', ({ successCount, totalCount, skippedCount, result }) => {
      createComponent({
        report: {
          success_count: successCount,
          skipped_count: skippedCount,
          total_count: totalCount,
        },
      });

      expect(successRate().text()).toBe(`${result}% success rate`);
    });
  });
});
