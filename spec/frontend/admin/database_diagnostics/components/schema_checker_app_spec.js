import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import SchemaCheckerApp from '~/admin/database_diagnostics/components/schema_checker_app.vue';
import SchemaResultsContainer from '~/admin/database_diagnostics/components/schema_results_container.vue';
import { schemaIssuesResults, noSchemaIssuesResults } from '../mock_data';

describe('SchemaCheckerApp component', () => {
  let wrapper;
  let mockAxios;

  const findTitle = () => wrapper.findByTestId('title');
  const findRunButton = () => wrapper.findByTestId('run-diagnostics-button');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findNoResultsMessage = () => wrapper.findByTestId('no-results-message');
  const findLastRun = () => wrapper.findByTestId('last-run');
  const findSchemaResultsContainer = () => wrapper.findComponent(SchemaResultsContainer);

  const runSchemaCheckUrl = '/admin/database_diagnostics/run_schema_check.json';
  const schemaCheckResultsUrl = '/admin/database_diagnostics/schema_check_results.json';

  const createComponent = () => {
    wrapper = shallowMountExtended(SchemaCheckerApp, {
      provide: {
        runSchemaCheckUrl,
        schemaCheckResultsUrl,
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
      mockAxios.onGet(schemaCheckResultsUrl).reply(404);
      createComponent();
    });

    it('shows a loading indicator initially', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders the title', () => {
      expect(findTitle().text()).toBe('Schema health check');
      expect(wrapper.text()).toContain(
        'Detect database schema inconsistencies and structural issues',
      );
    });

    it('shows no results message after loading', async () => {
      await waitForPromises();
      expect(findLastRun().exists()).toBe(false);
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findNoResultsMessage().text()).toBe(
        'Select "Run Schema Check" to analyze your database schema for potential issues.',
      );
    });

    it('enables the run button after loading completes', async () => {
      expect(findRunButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findRunButton().props('disabled')).toBe(false);
    });
  });

  describe('with results showing schema issues', () => {
    beforeEach(async () => {
      mockAxios.onGet(schemaCheckResultsUrl).reply(200, schemaIssuesResults);
      createComponent();
      await waitForPromises();
    });

    it('renders schema results container with correct props', () => {
      expect(findSchemaResultsContainer().props('schemaDiagnostics')).toEqual(schemaIssuesResults);
    });

    it('displays the last run timestamp', () => {
      expect(findLastRun().text()).toMatchInterpolatedText('Last checked: Jul 23, 2025, 10:00 AM');
    });
  });

  describe('with no issues', () => {
    beforeEach(async () => {
      mockAxios.onGet(schemaCheckResultsUrl).reply(200, noSchemaIssuesResults);
      createComponent();
      await waitForPromises();
    });

    it('renders schema results container for the database', () => {
      expect(findSchemaResultsContainer().props('schemaDiagnostics')).toEqual(
        noSchemaIssuesResults,
      );
    });
  });

  describe('running diagnostics', () => {
    beforeEach(async () => {
      mockAxios.onGet(schemaCheckResultsUrl).reply(404);
      mockAxios.onPost(runSchemaCheckUrl).reply(200);
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
      expect(mockAxios.history.post[0].url).toBe(runSchemaCheckUrl);
    });

    it('updates the view when results are available after fetching', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(true);

      mockAxios.onGet(schemaCheckResultsUrl).reply(200, schemaIssuesResults);

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findSchemaResultsContainer().exists()).toBe(true);
    });
  });

  describe('error handling', () => {
    it('displays error alert when initial API request fails', async () => {
      mockAxios.onGet(schemaCheckResultsUrl).reply(500, {
        error: 'Internal server error',
      });

      createComponent();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Internal server error');
    });

    it('displays error alert when run diagnostic request fails', async () => {
      // The component uses error.message when the post request fails
      mockAxios.onPost(runSchemaCheckUrl).replyOnce(500);

      createComponent();
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Request failed with status code 500');
    });
  });

  describe('schema diagnostics retry', () => {
    it('stops retries after reaching the maximum attempts', async () => {
      mockAxios.onGet(schemaCheckResultsUrl).reply(404);
      mockAxios.onPost(runSchemaCheckUrl).reply(200);

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

      // We expect 62 calls to schemaCheckResultsUrl:
      // 1 (initial call) + 1 (first try after post call) + 60 (retries after post call) = 62
      expect(mockAxios.history.get.filter((req) => req.url === schemaCheckResultsUrl)).toHaveLength(
        62,
      );
    });
  });
});
