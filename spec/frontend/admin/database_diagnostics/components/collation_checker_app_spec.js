import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import CollationCheckerApp from '~/admin/database_diagnostics/components/collation_checker_app.vue';
import DbDiagnosticResults from '~/admin/database_diagnostics/components/db_diagnostic_results.vue';
import DbIssuesCta from '~/admin/database_diagnostics/components/db_issues_cta.vue';
import { collationMismatchResults, noIssuesResults } from '../mock_data';

describe('CollationCheckerApp component', () => {
  let wrapper;
  let mockAxios;

  const findTitle = () => wrapper.findByTestId('title');
  const findRunButton = () => wrapper.findByTestId('run-diagnostics-button');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findNoResultsMessage = () => wrapper.findByTestId('no-results-message');
  const findLastRun = () => wrapper.findByTestId('last-run');

  // Database components
  const findDiagnosticResults = () => wrapper.findAllComponents(DbDiagnosticResults);
  const findIssuesCta = () => wrapper.findComponent(DbIssuesCta);

  const runCollationCheckUrl = '/admin/database_diagnostics/run_collation_check.json';
  const collationCheckResultsUrl = '/admin/database_diagnostics/collation_check_results.json';

  const createComponent = () => {
    wrapper = shallowMountExtended(CollationCheckerApp, {
      provide: {
        runCollationCheckUrl,
        collationCheckResultsUrl,
      },
    });
  };

  const clickRunDiagnosticsButton = async () => {
    findRunButton().vm.$emit('click');
    await nextTick();
  };

  beforeEach(() => {
    jest.useFakeTimers();
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
    jest.clearAllTimers();
  });

  describe('initial state', () => {
    beforeEach(() => {
      mockAxios.onGet(collationCheckResultsUrl).reply(404);
      createComponent();
    });

    it('shows a loading indicator initially', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders the title', () => {
      expect(findTitle().text()).toBe('Collation health check');
      expect(wrapper.text()).toContain(
        'Detect collation-related index corruption issues that might occur after OS upgrade',
      );
    });

    it('shows no results message after loading', async () => {
      await waitForPromises();
      expect(findLastRun().exists()).toBe(false);
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findNoResultsMessage().text()).toBe(
        'No diagnostics have been run yet. Click "Run Collation Check" to analyze your database for potential collation issues.',
      );
    });

    it('enables the run button after loading completes', async () => {
      expect(findRunButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findRunButton().props('disabled')).toBe(false);
    });
  });

  describe('with results showing collation mismatches', () => {
    beforeEach(async () => {
      mockAxios.onGet(collationCheckResultsUrl).reply(200, collationMismatchResults);
      createComponent();
      await waitForPromises();
    });

    it('renders diagnostic results components for both databases', () => {
      const results = findDiagnosticResults();
      expect(results).toHaveLength(2);
      expect(results.at(0).props('dbName')).toBe('main');
      expect(results.at(1).props('dbName')).toBe('ci');
    });

    it('passes the correct data to each diagnostic result component', () => {
      const results = findDiagnosticResults();
      expect(results.at(0).props('dbDiagnosticResult')).toEqual(
        collationMismatchResults.databases.main,
      );
      expect(results.at(1).props('dbDiagnosticResult')).toEqual(
        collationMismatchResults.databases.ci,
      );
    });

    it('displays the last run timestamp', () => {
      expect(findLastRun().text()).toMatchInterpolatedText('Last checked: Jul 23, 2025, 10:00 AM');
    });

    it('displays the issues CTA when corrupted indexes are found', () => {
      expect(findIssuesCta().exists()).toBe(true);
    });
  });

  describe('with no issues', () => {
    beforeEach(async () => {
      mockAxios.onGet(collationCheckResultsUrl).reply(200, noIssuesResults);
      createComponent();
      await waitForPromises();
    });

    it('renders diagnostic results component for the database', () => {
      const results = findDiagnosticResults();
      expect(results).toHaveLength(1);
      expect(results.at(0).props('dbName')).toBe('main');
    });

    it('does not display the issues CTA', () => {
      expect(findIssuesCta().exists()).toBe(false);
    });
  });

  describe('running diagnostics', () => {
    beforeEach(async () => {
      mockAxios.onGet(collationCheckResultsUrl).reply(404);
      mockAxios.onPost(runCollationCheckUrl).reply(200);
      createComponent();
      await waitForPromises();
    });

    it('shows loading state and disables button when run button is clicked', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findRunButton().props('disabled')).toBe(true);
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('makes the correct API call when run button is clicked', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(1);
      expect(mockAxios.history.post[0].url).toBe(runCollationCheckUrl);
    });

    it('updates the view when results are available after fetching', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(true);

      mockAxios.onGet(collationCheckResultsUrl).reply(200, collationMismatchResults);

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findDiagnosticResults()).toHaveLength(2);
    });
  });

  describe('error handling', () => {
    it('displays error alert when initial API request fails', async () => {
      mockAxios.onGet(collationCheckResultsUrl).reply(500, {
        error: 'Internal server error',
      });

      createComponent();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Internal server error');
    });

    it('displays error alert when run diagnostic request fails', async () => {
      // The component uses error.message when the post request fails
      mockAxios.onPost(runCollationCheckUrl).replyOnce(500);

      createComponent();
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Request failed with status code 500');
    });
  });

  describe('db diagnostics retry', () => {
    it('stops retries after reaching the maximum attempts', async () => {
      mockAxios.onGet(collationCheckResultsUrl).reply(404);
      mockAxios.onPost(runCollationCheckUrl).reply(200);

      createComponent();
      await waitForPromises();

      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(true);

      // We need to run runOnlyPendingTimers 60 times so that we exhaust maxRetryAttempts
      await [...Array(60)].reduce(async (promise) => {
        await promise;
        jest.runOnlyPendingTimers();
        await waitForPromises();
      }, Promise.resolve());

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findErrorAlert().text()).toBe(
        'The database diagnostic job is taking longer than expected. You can check back later or try running it again.',
      );

      // We expect 62 calls to collationCheckResultsUrl:
      // 1 (initial call) + 1 (first try after post call) + 60 (retries after post call) = 62
      expect(
        mockAxios.history.get.filter((req) => req.url === collationCheckResultsUrl),
      ).toHaveLength(62);
    });
  });
});
