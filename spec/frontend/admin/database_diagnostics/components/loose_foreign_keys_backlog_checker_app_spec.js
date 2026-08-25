import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import LooseForeignKeysBacklogCheckerApp from '~/admin/database_diagnostics/components/loose_foreign_keys_backlog_checker_app.vue';
import LfkBacklogResults from '~/admin/database_diagnostics/components/lfk_backlog_results.vue';
import { lfkBacklogResults, lfkNoBacklogResults } from '../mock_data';

describe('LooseForeignKeysBacklogCheckerApp component', () => {
  let wrapper;
  let mockAxios;

  const findTitle = () => wrapper.findByTestId('title');
  const findRunButton = () => wrapper.findComponentByTestId('run-diagnostics-button');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findLastRun = () => wrapper.findByTestId('last-run');
  const findResults = () => wrapper.findAllComponents(LfkBacklogResults);

  const runLfkBacklogCheckUrl = '/admin/database_diagnostics/run_lfk_backlog_check.json';
  const lfkBacklogCheckResultsUrl = '/admin/database_diagnostics/lfk_backlog_check_results.json';

  const createComponent = () => {
    wrapper = shallowMountExtended(LooseForeignKeysBacklogCheckerApp, {
      provide: {
        runLfkBacklogCheckUrl,
        lfkBacklogCheckResultsUrl,
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
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(404);
      createComponent();
    });

    it('shows a loading indicator initially', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders the title and description', () => {
      expect(findTitle().text()).toBe('Loose foreign keys cleanup backlog');
      expect(wrapper.text()).toContain('can eventually break database migrations');
    });

    it('enables the run button after loading completes', async () => {
      expect(findRunButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findRunButton().props('disabled')).toBe(false);
    });
  });

  describe('with a backlog', () => {
    beforeEach(async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(200, lfkBacklogResults);
      createComponent();
      await waitForPromises();
    });

    it('renders a results component per connection', () => {
      const results = findResults();
      expect(results).toHaveLength(2);
      expect(results.at(0).props('connectionName')).toBe('main');
      expect(results.at(1).props('connectionName')).toBe('ci');
    });

    it('passes each connection its backlog', () => {
      const results = findResults();
      expect(results.at(0).props('backlog')).toEqual(lfkBacklogResults.connections.main);
      expect(results.at(1).props('backlog')).toEqual(lfkBacklogResults.connections.ci);
    });

    it('displays the last run timestamp', () => {
      expect(findLastRun().text()).toMatchInterpolatedText('Last checked: Jul 23, 2025, 10:00 AM');
    });
  });

  describe('with no backlog', () => {
    beforeEach(async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(200, lfkNoBacklogResults);
      createComponent();
      await waitForPromises();
    });

    it('still renders a results component for the connection', () => {
      const results = findResults();
      expect(results).toHaveLength(1);
      expect(results.at(0).props('backlog')).toEqual([]);
    });
  });

  describe('running diagnostics', () => {
    beforeEach(async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(404);
      mockAxios.onPost(runLfkBacklogCheckUrl).reply(200);
      createComponent();
      await waitForPromises();
    });

    it('posts to the run URL and shows loading when the button is clicked', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(1);
      expect(mockAxios.history.post[0].url).toBe(runLfkBacklogCheckUrl);
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('updates the view once results become available', async () => {
      await clickRunDiagnosticsButton();
      await waitForPromises();

      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(200, lfkBacklogResults);

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findResults()).toHaveLength(2);
    });
  });

  describe('error handling', () => {
    it('displays an error alert when the results request fails', async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(500, { error: 'Internal server error' });

      createComponent();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Internal server error');
    });

    it('displays the server error message when starting diagnostics fails', async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(404);
      mockAxios.onPost(runLfkBacklogCheckUrl).reply(503, {
        error: 'Loose foreign keys backlog diagnostic is not enabled',
      });

      createComponent();
      await waitForPromises();

      await clickRunDiagnosticsButton();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe('Loose foreign keys backlog diagnostic is not enabled');
    });

    it('surfaces the message when the worker cached an error result', async () => {
      mockAxios.onGet(lfkBacklogCheckResultsUrl).reply(200, {
        error: true,
        message: 'PG::QueryCanceled: canceling statement due to statement timeout',
        metadata: { last_run_at: '2025-07-23T10:00:00Z' },
      });

      createComponent();
      await waitForPromises();

      expect(findErrorAlert().text()).toBe(
        'PG::QueryCanceled: canceling statement due to statement timeout',
      );
      expect(findResults()).toHaveLength(0);
    });
  });
});
