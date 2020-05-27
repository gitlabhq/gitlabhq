import MockAdapter from 'axios-mock-adapter';
import Poll from '~/lib/utils/poll';
import flashError from '~/flash';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { apiData } from '../mock_data';
import { MAX_REQUESTS } from '~/clusters_list/constants';
import * as types from '~/clusters_list/store/mutation_types';
import * as actions from '~/clusters_list/store/actions';
import * as Sentry from '@sentry/browser';

jest.mock('~/flash.js');

describe('Clusters store actions', () => {
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

    it('should commit SET_CLUSTERS_DATA with received response', done => {
      mock.onGet().reply(200, apiData, headers);

      testAction(
        actions.fetchClusters,
        { endpoint: apiData.endpoint },
        {},
        [
          { type: types.SET_CLUSTERS_DATA, payload: { data: apiData, paginationInformation } },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
        () => done(),
      );
    });

    it('should show flash on API error', done => {
      mock.onGet().reply(400, 'Not Found');

      testAction(
        actions.fetchClusters,
        { endpoint: apiData.endpoint },
        {},
        [{ type: types.SET_LOADING_STATE, payload: false }],
        [],
        () => {
          expect(flashError).toHaveBeenCalledWith(expect.stringMatching('error'));
          done();
        },
      );
    });

    describe('multiple api requests', () => {
      let captureException;
      let pollRequest;
      let pollStop;

      const pollInterval = 10;
      const pollHeaders = { 'poll-interval': pollInterval, ...headers };

      beforeEach(() => {
        captureException = jest.spyOn(Sentry, 'captureException');
        pollRequest = jest.spyOn(Poll.prototype, 'makeRequest');
        pollStop = jest.spyOn(Poll.prototype, 'stop');

        mock.onGet().reply(200, apiData, pollHeaders);
      });

      afterEach(() => {
        captureException.mockRestore();
        pollRequest.mockRestore();
        pollStop.mockRestore();
      });

      it('should stop polling after MAX Requests', done => {
        testAction(
          actions.fetchClusters,
          { endpoint: apiData.endpoint },
          {},
          [
            { type: types.SET_CLUSTERS_DATA, payload: { data: apiData, paginationInformation } },
            { type: types.SET_LOADING_STATE, payload: false },
          ],
          [],
          () => {
            expect(pollRequest).toHaveBeenCalledTimes(1);
            expect(pollStop).toHaveBeenCalledTimes(0);
            jest.advanceTimersByTime(pollInterval);

            waitForPromises()
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
              })
              .then(done)
              .catch(done.fail);
          },
        );
      });

      it('should stop polling and report to Sentry when data is invalid', done => {
        const badApiResponse = { clusters: {} };
        mock.onGet().reply(200, badApiResponse, pollHeaders);

        testAction(
          actions.fetchClusters,
          { endpoint: apiData.endpoint },
          {},
          [
            {
              type: types.SET_CLUSTERS_DATA,
              payload: { data: badApiResponse, paginationInformation },
            },
            { type: types.SET_LOADING_STATE, payload: false },
          ],
          [],
          () => {
            expect(pollRequest).toHaveBeenCalledTimes(1);
            expect(pollStop).toHaveBeenCalledTimes(1);
            expect(captureException).toHaveBeenCalledTimes(1);
            done();
          },
        );
      });
    });
  });
});
