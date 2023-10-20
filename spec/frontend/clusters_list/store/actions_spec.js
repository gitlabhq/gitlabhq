import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import testAction from 'helpers/vuex_action_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { MAX_REQUESTS } from '~/clusters_list/constants';
import * as actions from '~/clusters_list/store/actions';
import * as types from '~/clusters_list/store/mutation_types';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { apiData } from '../mock_data';

jest.mock('~/alert');

describe('Clusters store actions', () => {
  let captureException;

  describe('reportSentryError', () => {
    beforeEach(() => {
      captureException = jest.spyOn(Sentry, 'captureException');
    });

    afterEach(() => {
      captureException.mockRestore();
    });

    it('should report sentry error', async () => {
      const sentryError = new Error('New Sentry Error');
      const tag = 'sentryErrorTag';

      await testAction(actions.reportSentryError, { error: sentryError, tag }, {}, [], []);
      expect(captureException).toHaveBeenCalledWith(sentryError, {
        tags: {
          javascript_clusters_list: tag,
        },
      });
    });
  });

  describe('fetchClusters', () => {
    let mock;

    const headers = {
      'x-next-page': 1,
      'x-total': apiData.clusters.length,
      'x-total-pages': 1,
      'x-per-page': 20,
      'x-page': 1,
      'x-prev-page': 1,
    };

    const paginationInformation = {
      nextPage: 1,
      page: 1,
      perPage: 20,
      previousPage: 1,
      total: apiData.clusters.length,
      totalPages: 1,
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('should commit SET_CLUSTERS_DATA with received response', () => {
      mock.onGet().reply(HTTP_STATUS_OK, apiData, headers);

      return testAction(
        actions.fetchClusters,
        { endpoint: apiData.endpoint },
        {},
        [
          { type: types.SET_LOADING_NODES, payload: true },
          { type: types.SET_CLUSTERS_DATA, payload: { data: apiData, paginationInformation } },
          { type: types.SET_LOADING_CLUSTERS, payload: false },
        ],
        [],
      );
    });

    it('should show alert on API error', async () => {
      mock.onGet().reply(HTTP_STATUS_BAD_REQUEST, 'Not Found');

      await testAction(
        actions.fetchClusters,
        { endpoint: apiData.endpoint },
        {},
        [
          { type: types.SET_LOADING_NODES, payload: true },
          { type: types.SET_LOADING_CLUSTERS, payload: false },
          { type: types.SET_LOADING_NODES, payload: false },
        ],
        [
          {
            type: 'reportSentryError',
            payload: {
              error: new Error('Request failed with status code 400'),
              tag: 'fetchClustersErrorCallback',
            },
          },
        ],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: expect.stringMatching('error'),
      });
    });

    describe('multiple api requests', () => {
      let pollRequest;
      let pollStop;

      const pollInterval = 10;
      const pollHeaders = { 'poll-interval': pollInterval, ...headers };

      beforeEach(() => {
        pollRequest = jest.spyOn(Poll.prototype, 'makeRequest');
        pollStop = jest.spyOn(Poll.prototype, 'stop');

        mock.onGet().reply(HTTP_STATUS_OK, apiData, pollHeaders);
      });

      afterEach(() => {
        pollRequest.mockRestore();
        pollStop.mockRestore();
      });

      it('should stop polling after MAX Requests', async () => {
        await testAction(
          actions.fetchClusters,
          { endpoint: apiData.endpoint },
          {},
          [
            { type: types.SET_LOADING_NODES, payload: true },
            { type: types.SET_CLUSTERS_DATA, payload: { data: apiData, paginationInformation } },
            { type: types.SET_LOADING_CLUSTERS, payload: false },
          ],
          [],
        );
        expect(pollRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(0);
        jest.advanceTimersByTime(pollInterval);

        return waitForPromises()
          .then(() => {
            expect(pollRequest).toHaveBeenCalledTimes(2);
            expect(pollStop).toHaveBeenCalledTimes(0);
            jest.advanceTimersByTime(pollInterval);
          })
          .then(() => waitForPromises())
          .then(() => {
            expect(pollRequest).toHaveBeenCalledTimes(MAX_REQUESTS);
            expect(pollStop).toHaveBeenCalledTimes(0);
            jest.advanceTimersByTime(pollInterval);
          })
          .then(() => waitForPromises())
          .then(() => {
            expect(pollRequest).toHaveBeenCalledTimes(MAX_REQUESTS + 1);
            // Stops poll once it exceeds the MAX_REQUESTS limit
            expect(pollStop).toHaveBeenCalledTimes(1);
            jest.advanceTimersByTime(pollInterval);
          })
          .then(() => waitForPromises())
          .then(() => {
            // Additional poll requests are not made once pollStop is called
            expect(pollRequest).toHaveBeenCalledTimes(MAX_REQUESTS + 1);
            expect(pollStop).toHaveBeenCalledTimes(1);
          });
      });

      it('should stop polling and report to Sentry when data is invalid', async () => {
        const badApiResponse = { clusters: {} };
        mock.onGet().reply(HTTP_STATUS_OK, badApiResponse, pollHeaders);

        await testAction(
          actions.fetchClusters,
          { endpoint: apiData.endpoint },
          {},
          [
            { type: types.SET_LOADING_NODES, payload: true },
            {
              type: types.SET_CLUSTERS_DATA,
              payload: { data: badApiResponse, paginationInformation },
            },
            { type: types.SET_LOADING_CLUSTERS, payload: false },
            { type: types.SET_LOADING_CLUSTERS, payload: false },
            { type: types.SET_LOADING_NODES, payload: false },
          ],
          [
            {
              type: 'reportSentryError',
              payload: {
                error: new Error('clusters.every is not a function'),
                tag: 'fetchClustersSuccessCallback',
              },
            },
          ],
        );
        expect(pollRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(1);
      });
    });
  });
});
