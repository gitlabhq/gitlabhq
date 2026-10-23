import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import { createAlert } from '~/alert';
import { useAdminStatistics } from '~/admin/statistics_panel/store';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import mockStatistics from '../mock_data';

jest.mock('~/alert');

describe('Admin statistics panel store', () => {
  let store;
  let mock;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useAdminStatistics();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getters', () => {
    describe('getStatistics', () => {
      const statisticsLabels = {
        forks: 'Forks',
        issues: 'Issues',
      };

      describe('when statistics data exists', () => {
        it('returns an array of statistics objects with key, label and value', () => {
          store.statistics = { forks: 10, issues: 20 };

          expect(store.getStatistics(statisticsLabels)).toEqual([
            { key: 'forks', label: 'Forks', value: 10 },
            { key: 'issues', label: 'Issues', value: 20 },
          ]);
        });
      });

      describe('when no statistics data exists', () => {
        it('returns an array of statistics objects with key, label and sets value to null', () => {
          store.statistics = null;

          expect(store.getStatistics(statisticsLabels)).toEqual([
            { key: 'forks', label: 'Forks', value: null },
            { key: 'issues', label: 'Issues', value: null },
          ]);
        });
      });
    });
  });

  describe('actions', () => {
    describe('fetchStatistics', () => {
      describe('success', () => {
        beforeEach(() => {
          mock
            .onGet(/api\/(.*)\/application\/statistics/)
            .replyOnce(HTTP_STATUS_OK, mockStatistics);
        });

        it('requests the statistics and stores the received data', async () => {
          jest.spyOn(store, 'requestStatistics');
          jest.spyOn(store, 'receiveStatisticsSuccess');

          const promise = store.fetchStatistics();

          expect(store.requestStatistics).toHaveBeenCalledTimes(1);
          expect(store.isLoading).toBe(true);

          await promise;

          expect(store.receiveStatisticsSuccess).toHaveBeenCalledWith(
            expect.objectContaining(convertObjectPropsToCamelCase(mockStatistics, { deep: true })),
          );
          expect(store.isLoading).toBe(false);
          expect(store.statistics).toEqual(
            convertObjectPropsToCamelCase(mockStatistics, { deep: true }),
          );
        });
      });

      describe('error', () => {
        beforeEach(() => {
          mock
            .onGet(/api\/(.*)\/application\/statistics/)
            .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('requests the statistics and handles the error', async () => {
          jest.spyOn(store, 'requestStatistics');
          jest.spyOn(store, 'receiveStatisticsError');

          await store.fetchStatistics();

          expect(store.requestStatistics).toHaveBeenCalledTimes(1);
          expect(store.receiveStatisticsError).toHaveBeenCalledWith(
            new Error('Request failed with status code 500'),
          );
          expect(store.isLoading).toBe(false);
          expect(store.error).toEqual(new Error('Request failed with status code 500'));
          expect(store.statistics).toBe(null);
        });
      });
    });

    describe('requestStatistics', () => {
      it('sets isLoading to true', () => {
        store.requestStatistics();

        expect(store.isLoading).toBe(true);
      });
    });

    describe('receiveStatisticsSuccess', () => {
      it('updates the store with the statistics', () => {
        store.isLoading = true;
        store.error = new Error('previous error');

        store.receiveStatisticsSuccess(mockStatistics);

        expect(store.isLoading).toBe(false);
        expect(store.error).toBe(null);
        expect(store.statistics).toEqual(mockStatistics);
      });
    });

    describe('receiveStatisticsError', () => {
      it('sets the error, clears loading and creates an alert', () => {
        store.isLoading = true;

        store.receiveStatisticsError(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        expect(store.isLoading).toBe(false);
        expect(store.error).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        expect(store.statistics).toBe(null);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Error loading the statistics. Please try again',
        });
      });
    });
  });
});
