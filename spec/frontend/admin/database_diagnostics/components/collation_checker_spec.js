import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import CollationChecker from '~/admin/database_diagnostics/components/collation_checker.vue';

describe('CollationChecker component', () => {
  let wrapper;
  let mockAxios;

  // Set shorter polling values for tests to keep them fast
  const TEST_POLLING_INTERVAL_MS = 50;
  const TEST_MAX_POLLING_ATTEMPTS = 2;

  const findTitle = () => wrapper.findByTestId('title');
  const findRunButton = () => wrapper.findByTestId('run-diagnostics-button');
  const findLoadingAlert = () => wrapper.findByTestId('loading-alert');
  const findRunningAlert = () => wrapper.findByTestId('running-alert');
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findNoResultsMessage = () => wrapper.findByTestId('no-results-message');

  // Database sections
  const findDatabaseMain = () => wrapper.findByTestId('database-main');
  const findDatabaseCI = () => wrapper.findByTestId('database-ci');

  // Other sections
  const findCollationInfoAlert = () => wrapper.findByTestId('collation-info-alert');
  const findCorruptedIndexesTable = () => wrapper.findByTestId('corrupted-indexes-table');
  const findNoCollationMismatchesAlert = () =>
    wrapper.findByTestId('no-collation-mismatches-alert');
  const findNoCorruptedIndexesAlert = () => wrapper.findByTestId('no-corrupted-indexes-alert');

  // Action card
  const findActionCard = () => wrapper.findByTestId('action-card');
  const findLearnMoreButton = () => wrapper.findByTestId('learn-more-button');
  const findContactSupportButton = () => wrapper.findByTestId('contact-support-button');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CollationChecker, {
      propsData: {
        runCollationCheckUrl: '/admin/database_diagnostics/run_collation_check.json',
        collationCheckResultsUrl: '/admin/database_diagnostics/collation_check_results.json',
        pollingIntervalMs: TEST_POLLING_INTERVAL_MS,
        maxPollingAttempts: TEST_MAX_POLLING_ATTEMPTS,
        ...props,
      },
    });
  };

  const clickRunButton = async () => {
    findRunButton().vm.$emit('click');
    await nextTick();
  };

  const collationMismatchResults = {
    metadata: {
      last_run_at: '2025-07-23T10:00:00Z',
    },
    databases: {
      main: {
        collation_mismatches: [
          {
            collation_name: 'en_US.UTF-8',
            provider: 'c',
            stored_version: '2.28',
            actual_version: '2.31',
          },
        ],
        corrupted_indexes: [
          {
            index_name: 'index_users_on_name',
            table_name: 'users',
            affected_columns: 'name',
            index_type: 'btree',
            is_unique: true,
            size_bytes: 5678901,
            corruption_types: ['duplicates'],
            needs_deduplication: true,
          },
        ],
      },
      ci: {
        collation_mismatches: [],
        corrupted_indexes: [],
      },
    },
  };

  const noIssuesResults = {
    metadata: {
      last_run_at: '2025-07-23T10:00:00Z',
    },
    databases: {
      main: {
        collation_mismatches: [],
        corrupted_indexes: [],
      },
    },
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
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(404);
      createComponent();
    });

    it('shows a loading indicator initially', () => {
      expect(findLoadingAlert().exists()).toBe(true);
      expect(findLoadingAlert().findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders the title', async () => {
      await waitForPromises();

      expect(findTitle().exists()).toBe(true);
    });

    it('shows no results message after loading', async () => {
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(404);
      createComponent();
      await waitForPromises();

      expect(findLoadingAlert().exists()).toBe(false);
      expect(findNoResultsMessage().exists()).toBe(true);
    });

    it('enables the run button after loading completes', async () => {
      expect(findRunButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findRunButton().props('disabled')).toBe(false);
    });
  });

  describe('with results showing collation mismatches', () => {
    beforeEach(async () => {
      mockAxios
        .onGet('/admin/database_diagnostics/collation_check_results.json')
        .reply(200, collationMismatchResults);
      createComponent();
      await waitForPromises();
    });

    it('renders both database sections', () => {
      expect(findDatabaseMain().exists()).toBe(true);
      expect(findDatabaseCI().exists()).toBe(true);
    });

    it('displays collation mismatches alert', () => {
      expect(findCollationInfoAlert().exists()).toBe(true);
    });

    it('displays corrupted indexes table', () => {
      expect(findCorruptedIndexesTable().exists()).toBe(true);
    });

    it('displays action card with remediation links', () => {
      expect(findActionCard().exists()).toBe(true);
      expect(findLearnMoreButton().exists()).toBe(true);
      expect(findContactSupportButton().exists()).toBe(true);
    });
  });

  describe('with no issues', () => {
    beforeEach(async () => {
      mockAxios
        .onGet('/admin/database_diagnostics/collation_check_results.json')
        .reply(200, noIssuesResults);
      createComponent();
      await waitForPromises();
    });

    it('shows success alerts for no mismatches and no corrupted indexes', () => {
      expect(findNoCollationMismatchesAlert().exists()).toBe(true);
      expect(findNoCorruptedIndexesAlert().exists()).toBe(true);
    });

    it('does not display the action card', () => {
      expect(findActionCard().exists()).toBe(false);
    });
  });

  describe('running diagnostics', () => {
    beforeEach(async () => {
      // Initial load - no results
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(404);
      mockAxios.onPost('/admin/database_diagnostics/run_collation_check.json').reply(200);
      createComponent();
      await waitForPromises();
    });

    it('shows loading state and disables button when run button is clicked', async () => {
      await clickRunButton();

      expect(findRunButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findRunningAlert().exists()).toBe(true);
      expect(findRunButton().props('disabled')).toBe(true);
    });

    it('makes the correct API call when run button is clicked', async () => {
      await clickRunButton();
      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(1);
      expect(mockAxios.history.post[0].url).toBe(
        '/admin/database_diagnostics/run_collation_check.json',
      );
    });

    it('updates the view when results are available after polling', async () => {
      await clickRunButton();
      await waitForPromises();

      expect(findRunningAlert().exists()).toBe(true);

      mockAxios
        .onGet('/admin/database_diagnostics/collation_check_results.json')
        .reply(200, collationMismatchResults);

      jest.advanceTimersByTime(TEST_POLLING_INTERVAL_MS);
      await nextTick();
      await waitForPromises();

      expect(findRunningAlert().exists()).toBe(false);
      expect(findDatabaseMain().exists()).toBe(true);
    });
  });

  describe('error handling', () => {
    it('displays error alert when initial API request fails', async () => {
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(500, {
        error: 'Internal server error',
      });

      createComponent();
      await waitForPromises();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Internal server error');
    });

    it('displays error alert when run diagnostic request fails', async () => {
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(404);
      mockAxios.onPost('/admin/database_diagnostics/run_collation_check.json').reply(500, {
        error: 'Failed to schedule diagnostics',
      });

      createComponent();
      await waitForPromises();

      await clickRunButton();
      await waitForPromises();

      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('Failed to schedule diagnostics');
    });
  });

  describe('polling', () => {
    it('stops polling after reaching the maximum attempts', async () => {
      // Set up API mocks
      mockAxios.onGet('/admin/database_diagnostics/collation_check_results.json').reply(404);
      mockAxios.onPost('/admin/database_diagnostics/run_collation_check.json').reply(200);

      createComponent();
      await waitForPromises();

      // Use our custom helper to simulate user clicking the button
      await clickRunButton();
      await waitForPromises();

      // Verify initial state
      expect(findRunningAlert().exists()).toBe(true);

      await jest.advanceTimersByTime(TEST_POLLING_INTERVAL_MS * TEST_MAX_POLLING_ATTEMPTS);
      await waitForPromises();

      // Verify polling has stopped and error is shown
      expect(findRunningAlert().exists()).toBe(false);
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toContain('taking longer than expected');
    });
  });
});
