import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import GroupedTestReportsApp from '~/reports/components/grouped_test_reports_app.vue';
import store from '~/reports/store';

import { failedReport } from '../mock_data/mock_data';
import successTestReports from '../mock_data/no_failures_report.json';
import newFailedTestReports from '../mock_data/new_failures_report.json';
import newErrorsTestReports from '../mock_data/new_errors_report.json';
import mixedResultsTestReports from '../mock_data/new_and_fixed_failures_report.json';
import resolvedFailures from '../mock_data/resolved_failures.json';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Grouped test reports app', () => {
  const endpoint = 'endpoint.json';
  const Component = localVue.extend(GroupedTestReportsApp);
  let wrapper;
  let mockStore;

  const mountComponent = () => {
    wrapper = mount(Component, {
      store: mockStore,
      localVue,
      propsData: {
        endpoint,
      },
      methods: {
        fetchReports: () => {},
      },
    });
  };

  const setReports = reports => {
    mockStore.state.status = reports.status;
    mockStore.state.summary = reports.summary;
    mockStore.state.reports = reports.suites;
  };

  const findHeader = () => wrapper.find('[data-testid="report-section-code-text"]');
  const findSummaryDescription = () => wrapper.find('[data-testid="test-summary-row-description"]');
  const findIssueDescription = () => wrapper.find('[data-testid="test-issue-body-description"]');
  const findAllIssueDescriptions = () =>
    wrapper.findAll('[data-testid="test-issue-body-description"]');

  beforeEach(() => {
    mockStore = store();
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
