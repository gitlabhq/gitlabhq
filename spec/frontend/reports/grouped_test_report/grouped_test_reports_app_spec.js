import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Api from '~/api';
import GroupedTestReportsApp from '~/reports/grouped_test_report/grouped_test_reports_app.vue';
import { getStoreConfig } from '~/reports/grouped_test_report/store';

import { failedReport } from '../mock_data/mock_data';
import mixedResultsTestReports from '../mock_data/new_and_fixed_failures_report.json';
import newErrorsTestReports from '../mock_data/new_errors_report.json';
import newFailedTestReports from '../mock_data/new_failures_report.json';
import successTestReports from '../mock_data/no_failures_report.json';
import recentFailuresTestReports from '../mock_data/recent_failures_report.json';
import resolvedFailures from '../mock_data/resolved_failures.json';

jest.mock('~/api.js');

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Grouped test reports app', () => {
  const endpoint = 'endpoint.json';
  const headBlobPath = '/blob/path';
  const pipelinePath = '/path/to/pipeline';
  let wrapper;
  let mockStore;

  const mountComponent = ({ props = { pipelinePath }, glFeatures = {} } = {}) => {
    wrapper = mount(GroupedTestReportsApp, {
      store: mockStore,
      localVue,
      propsData: {
        endpoint,
        headBlobPath,
        pipelinePath,
        ...props,
      },
      provide: {
        glFeatures,
      },
    });
  };

  const setReports = (reports) => {
    mockStore.state.status = reports.status;
    mockStore.state.summary = reports.summary;
    mockStore.state.reports = reports.suites;
  };

  const findHeader = () => wrapper.find('[data-testid="report-section-code-text"]');
  const findExpandButton = () => wrapper.find('[data-testid="report-section-expand-button"]');
  const findFullTestReportLink = () => wrapper.find('[data-testid="group-test-reports-full-link"]');
  const findSummaryDescription = () => wrapper.find('[data-testid="summary-row-description"]');
  const findIssueListUnresolvedHeading = () => wrapper.find('[data-testid="unresolvedHeading"]');
  const findIssueListResolvedHeading = () => wrapper.find('[data-testid="resolvedHeading"]');
  const findIssueDescription = () => wrapper.find('[data-testid="test-issue-body-description"]');
  const findIssueRecentFailures = () =>
    wrapper.find('[data-testid="test-issue-body-recent-failures"]');
  const findAllIssueDescriptions = () =>
    wrapper.findAll('[data-testid="test-issue-body-description"]');

  beforeEach(() => {
    mockStore = new Vuex.Store({
      ...getStoreConfig(),
      actions: {
        fetchReports: () => {},
        setPaths: () => {},
      },
    });
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with success result', () => {
    beforeEach(() => {
      setReports(successTestReports);
      mountComponent();
    });

    it('renders success summary text', () => {
      expect(findHeader().text()).toBe(
        'Test summary contained no changed test results out of 11 total tests',
      );
    });
  });

  describe('`View full report` button', () => {
    it('should render the full test report link', () => {
      const fullTestReportLink = findFullTestReportLink();

      expect(fullTestReportLink.exists()).toBe(true);
      expect(pipelinePath).not.toBe('');
      expect(fullTestReportLink.attributes('href')).toBe(`${pipelinePath}/test_report`);
    });

    describe('Without a pipelinePath', () => {
      beforeEach(() => {
        mountComponent({
          props: { pipelinePath: '' },
        });
      });

      it('should not render the full test report link', () => {
        expect(findFullTestReportLink().exists()).toBe(false);
      });
    });
  });

  describe('`Expand` button', () => {
    beforeEach(() => {
      setReports(newFailedTestReports);
    });

    it('tracks service ping metric when enabled', () => {
      mountComponent({ glFeatures: { usageDataITestingSummaryWidgetTotal: true } });
      findExpandButton().trigger('click');

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(wrapper.vm.$options.expandEvent);
    });

    it('only tracks the first expansion', () => {
      mountComponent({ glFeatures: { usageDataITestingSummaryWidgetTotal: true } });
      const expandButton = findExpandButton();
      expandButton.trigger('click');
      expandButton.trigger('click');
      expandButton.trigger('click');

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
    });

    it('does not track service ping metric when disabled', () => {
      mountComponent({ glFeatures: { usageDataITestingSummaryWidgetTotal: false } });
      findExpandButton().trigger('click');

      expect(Api.trackRedisHllUserEvent).not.toHaveBeenCalled();
    });
  });

  describe('with new failed result', () => {
    beforeEach(() => {
      setReports(newFailedTestReports);
      mountComponent();
    });

    it('renders New heading', () => {
      expect(findIssueListUnresolvedHeading().text()).toBe('New');
    });

    it('renders failed summary text', () => {
      expect(findHeader().text()).toBe('Test summary contained 2 failed out of 11 total tests');
    });

    it('renders failed test suite', () => {
      expect(findSummaryDescription().text()).toContain(
        'rspec:pg found 2 failed out of 8 total tests',
      );
    });

    it('renders failed issue in list', () => {
      expect(findIssueDescription().text()).toContain(
        'Test#sum when a is 1 and b is 2 returns summary',
      );
    });
  });

  describe('with new error result', () => {
    beforeEach(() => {
      setReports(newErrorsTestReports);
      mountComponent();
    });

    it('renders New heading', () => {
      expect(findIssueListUnresolvedHeading().text()).toBe('New');
    });

    it('renders error summary text', () => {
      expect(findHeader().text()).toBe('Test summary contained 2 errors out of 11 total tests');
    });

    it('renders error test suite', () => {
      expect(findSummaryDescription().text()).toContain(
        'karma found 2 errors out of 3 total tests',
      );
    });

    it('renders error issue in list', () => {
      expect(findIssueDescription().text()).toContain(
        'Test#sum when a is 1 and b is 2 returns summary',
      );
    });
  });

  describe('with mixed results', () => {
    beforeEach(() => {
      setReports(mixedResultsTestReports);
      mountComponent();
    });

    it('renders New and Fixed headings', () => {
      expect(findIssueListUnresolvedHeading().text()).toBe('New');
      expect(findIssueListResolvedHeading().text()).toBe('Fixed');
    });

    it('renders summary text', () => {
      expect(findHeader().text()).toBe(
        'Test summary contained 2 failed and 2 fixed test results out of 11 total tests',
      );
    });

    it('renders failed test suite', () => {
      expect(findSummaryDescription().text()).toContain(
        'rspec:pg found 1 failed and 2 fixed test results out of 8 total tests',
      );
    });

    it('renders failed issue in list', () => {
      expect(findIssueDescription().text()).toContain(
        'Test#subtract when a is 2 and b is 1 returns correct result',
      );
    });
  });

  describe('with resolved failures and resolved errors', () => {
    beforeEach(() => {
      setReports(resolvedFailures);
      mountComponent();
    });

    it('renders Fixed heading', () => {
      expect(findIssueListResolvedHeading().text()).toBe('Fixed');
    });

    it('renders summary text', () => {
      expect(findHeader().text()).toBe(
        'Test summary contained 4 fixed test results out of 11 total tests',
      );
    });

    it('renders resolved test suite', () => {
      expect(findSummaryDescription().text()).toContain(
        'rspec:pg found 4 fixed test results out of 8 total tests',
      );
    });

    it('renders resolved failures', () => {
      expect(findIssueDescription().text()).toContain(
        resolvedFailures.suites[0].resolved_failures[0].name,
      );
    });

    it('renders resolved errors', () => {
      expect(findAllIssueDescriptions().at(2).text()).toContain(
        resolvedFailures.suites[0].resolved_errors[0].name,
      );
    });
  });

  describe('recent failures counts', () => {
    describe('with recent failures counts', () => {
      beforeEach(() => {
        setReports(recentFailuresTestReports);
        mountComponent();
      });

      it('renders the recently failed tests summary', () => {
        expect(findHeader().text()).toContain(
          '2 out of 3 failed tests have failed more than once in the last 14 days',
        );
      });

      it('renders the recently failed count on the test suite', () => {
        expect(findSummaryDescription().text()).toContain(
          '1 out of 2 failed tests has failed more than once in the last 14 days',
        );
      });

      it('renders the recent failures count on the test case', () => {
        expect(findIssueRecentFailures().text()).toBe('Failed 8 times in main in the last 14 days');
      });
    });

    describe('without recent failures counts', () => {
      beforeEach(() => {
        setReports(mixedResultsTestReports);
        mountComponent();
      });

      it('does not render the recently failed tests summary', () => {
        expect(findHeader().text()).not.toContain('failed more than once in the last 14 days');
      });

      it('does not render the recently failed count on the test suite', () => {
        expect(findSummaryDescription().text()).not.toContain(
          'failed more than once in the last 14 days',
        );
      });

      it('does not render the recent failures count on the test case', () => {
        expect(findIssueDescription().text()).not.toContain('in the last 14 days');
      });
    });
  });

  describe('with a report that failed to load', () => {
    beforeEach(() => {
      setReports(failedReport);
      mountComponent();
    });

    it('renders an error status for the report', () => {
      const { name } = failedReport.suites[0];

      expect(findSummaryDescription().text()).toContain(
        `An error occurred while loading ${name} result`,
      );
    });
  });

  describe('with a report parsing errors', () => {
    beforeEach(() => {
      const reports = failedReport;
      reports.suites[0].suite_errors = {
        head: 'JUnit XML parsing failed: 2:24: FATAL: attributes construct error',
        base: 'JUnit data parsing failed: string not matched',
      };
      setReports(reports);
      mountComponent();
    });

    it('renders the error messages', () => {
      expect(findSummaryDescription().text()).toContain(
        'JUnit XML parsing failed: 2:24: FATAL: attributes construct error',
      );
      expect(findSummaryDescription().text()).toContain(
        'JUnit data parsing failed: string not matched',
      );
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mockStore.state.isLoading = false;
      mockStore.state.hasError = true;
      mountComponent();
    });

    it('renders loading state', () => {
      expect(findHeader().text()).toBe('Test summary failed loading results');
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      mockStore.state.isLoading = true;
      mountComponent();
    });

    it('renders loading state', () => {
      expect(findHeader().text()).toBe('Test summary results are being parsed');
    });
  });
});
