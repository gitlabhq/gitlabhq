import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import {
  useArtifactsList,
  clearEtagPoll,
  stopPolling,
} from '~/vue_merge_request_widget/stores/artifacts_list';
import { artifacts } from '../../mock_data';

describe('Artifacts list store', () => {
  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useArtifactsList();
  });

  describe('setEndpoint', () => {
    it('sets the endpoint', () => {
      store.setEndpoint('endpoint.json');

      expect(store.endpoint).toBe('endpoint.json');
    });
  });

  describe('requestArtifacts', () => {
    it('sets isLoading to true', () => {
      store.requestArtifacts();

      expect(store.isLoading).toBe(true);
    });
  });

  describe('fetchArtifacts', () => {
    let mock;

    beforeAll(() => {
      mock = new MockAdapter(axios);
    });

    beforeEach(() => {
      store.endpoint = `${TEST_HOST}/endpoint.json`;
    });

    afterEach(() => {
      mock.reset();
      stopPolling();
      clearEtagPoll();
    });

    afterAll(() => {
      mock.restore();
    });

    describe('success', () => {
      it('sets artifacts on success', async () => {
        const responseData = [
          {
            text: 'result.txt',
            url: 'asda',
            job_name: 'generate-artifact',
            job_path: 'asda',
          },
        ];
        mock.onGet(`${TEST_HOST}/endpoint.json`).replyOnce(HTTP_STATUS_OK, responseData);

        store.fetchArtifacts();

        await axios.waitForAll();

        expect(store.isLoading).toBe(false);
        expect(store.hasError).toBe(false);
        expect(store.artifacts).toEqual(responseData);
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/endpoint.json`).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('sets error state on failure', async () => {
        store.fetchArtifacts();

        await axios.waitForAll();

        expect(store.isLoading).toBe(false);
        expect(store.hasError).toBe(true);
        expect(store.artifacts).toEqual([]);
      });
    });
  });

  describe('receiveArtifactsSuccess', () => {
    it('sets artifacts with 200 status', () => {
      store.receiveArtifactsSuccess({ data: { summary: {} }, status: HTTP_STATUS_OK });

      expect(store.artifacts).toEqual({ summary: {} });
      expect(store.isLoading).toBe(false);
      expect(store.hasError).toBe(false);
    });

    it('does not update state with 204 status', () => {
      store.isLoading = true;
      store.receiveArtifactsSuccess({ data: { summary: {} }, status: HTTP_STATUS_NO_CONTENT });

      expect(store.isLoading).toBe(true);
      expect(store.artifacts).toEqual([]);
    });
  });

  describe('receiveArtifactsError', () => {
    it('sets error state', () => {
      store.receiveArtifactsError();

      expect(store.isLoading).toBe(false);
      expect(store.hasError).toBe(true);
      expect(store.artifacts).toEqual([]);
    });
  });

  describe('title getter', () => {
    it('returns loading message when loading', () => {
      store.isLoading = true;

      expect(store.title).toBe('Loading artifacts');
    });

    it('returns error message when has error', () => {
      store.hasError = true;

      expect(store.title).toBe('An error occurred while fetching the artifacts');
    });

    it('returns artifacts count message', () => {
      store.artifacts = artifacts;

      expect(store.title).toBe('View 2 exposed artifacts');
    });
  });
});
