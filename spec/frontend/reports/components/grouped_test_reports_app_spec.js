import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import GroupedTestReportsApp from '~/reports/components/grouped_test_reports_app.vue';
import { getStoreConfig } from '~/reports/store';

import { failedReport } from '../mock_data/mock_data';
import successTestReports from '../mock_data/no_failures_report.json';
import newFailedTestReports from '../mock_data/new_failures_report.json';
import recentFailuresTestReports from '../mock_data/recent_failures_report.json';
import newErrorsTestReports from '../mock_data/new_errors_report.json';
import mixedResultsTestReports from '../mock_data/new_and_fixed_failures_report.json';
import resolvedFailures from '../mock_data/resolved_failures.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Grouped test reports app', () => {
  const endpoint = 'endpoint.json';
  const pipelinePath = '/path/to/pipeline';
  const Component = localVue.extend(GroupedTestReportsApp);
  let wrapper;
  let mockStore;

  const mountComponent = ({ props = { pipelinePath }, testFailureHistory = false } = {}) => {
    wrapper = mount(Component, {
      store: mockStore,
      localVue,
      propsData: {
        endpoint,
        pipelinePath,
        ...props,
      },
      provide: {
        glFeatures: {
          testFailureHistory,
        },
      },
    });
  };

  const setReports = reports => {
    mockStore.state.status = reports.status;
    mockStore.state.summary = reports.summary;
    mockStore.state.reports = reports.suites;
  };

  const findHeader = () => wrapper.find('[data-testid="report-section-code-text"]');
  const findExpandButton = () => wrapper.find('[data-testid="report-section-expand-button"]');
  const findFullTestReportLink = () => wrapper.find('[data-testid="group-test-reports-full-link"]');
  const findSummaryDescription = () => wrapper.find('[data-testid="test-summary-row-description"]');
  const findIssueDescription = () => wrapper.find('[data-testid="test-issue-body-description"]');
  const findAllIssueDescriptions = () =>
    wrapper.findAll('[data-testid="test-issue-body-description"]');

  beforeEach(() => {
    mockStore = new Vuex.Store({
      ...getStoreConfig(),
      actions: {
        fetchReports: () => {},
        setEndpoint: () => {},
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
    let trackingSpy;

    beforeEach(() => {
      setReports(newFailedTestReports);
      mountComponent();
      document.body.dataset.page = 'projects:merge_requests:show';
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    });

    it('tracks an event on click', () => {
      findExpandButton().trigger('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'expand_test_report_widget', {});
    });

    it('only tracks the first expansion', () => {
      expect(trackingSpy).not.toHaveBeenCalled();

      const button = findExpandButton();

      button.trigger('click');
      button.trigger('click');
      button.trigger('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('with new failed result', () => {
    beforeEach(() => {
      setReports(newFailedTestReports);
      mountComponent();
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
      expect(findIssueDescription().text()).toContain('New');
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

    it('renders error summary text', () => {
      expect(findHeader().text()).toBe('Test summary contained 2 errors out of 11 total tests');
    });

    it('renders error test suite', () => {
      expect(findSummaryDescription().text()).toContain(
        'karma found 2 errors out of 3 total tests',
      );
    });

    it('renders error issue in list', () => {
      expect(findIssueDescription().text()).toContain('New');
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
      expect(findIssueDescription().text()).toContain('New');
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
      expect(
        findAllIssueDescriptions()
          .at(2)
          .text(),
      ).toContain(resolvedFailures.suites[0].resolved_errors[0].name);
    });
  });

  describe('recent failures counts', () => {
    describe('with recent failures counts', () => {
      beforeEach(() => {
        setReports(recentFailuresTestReports);
      });

      describe('with feature flag enabled', () => {
        beforeEach(() => {
          mountComponent({ testFailureHistory: true });
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
          expect(findIssueDescription().text()).toContain(
            'Failed 8 times in master in the last 14 days',
          );
        });
      });

      describe('with feature flag disabled', () => {
        beforeEach(() => {
          mountComponent({ testFailureHistory: false });
        });

        it('does not render the recently failed tests summary', () => {
          expect(findHeader().text()).not.toContain('failed more than once in the last 14 days');
        });

        it('does not render the recently failed count on the test suite', () => {
          expect(findSummaryDescription().text()).not.toContain(
            'failed more than once in the last 14 days',
          );
        });

        it('renders the recent failures count on the test case', () => {
          expect(findIssueDescription().text()).not.toContain('in the last 14 days');
        });
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
