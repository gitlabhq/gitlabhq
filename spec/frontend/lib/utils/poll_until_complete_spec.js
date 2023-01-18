import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import pollUntilComplete from '~/lib/utils/poll_until_complete';

const endpoint = `${TEST_HOST}/foo`;
const mockData = 'mockData';
const pollInterval = 1234;
const pollIntervalHeader = {
  'Poll-Interval': pollInterval,
};

describe('pollUntilComplete', () => {
  let mock;

  beforeEach(() => {
    mock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('given an immediate success response', () => {
    beforeEach(() => {
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_OK, mockData);
    });

    it('resolves with the response', () =>
      pollUntilComplete(endpoint).then(({ data }) => {
        expect(data).toBe(mockData);
      }));
  });

  describe(`given the endpoint returns NO_CONTENT with a Poll-Interval before succeeding`, () => {
    beforeEach(() => {
      mock
        .onGet(endpoint)
        .replyOnce(HTTP_STATUS_NO_CONTENT, undefined, pollIntervalHeader)
        .onGet(endpoint)
        .replyOnce(HTTP_STATUS_OK, mockData);
    });

    it('calls the endpoint until it succeeds, and resolves with the response', () =>
      Promise.all([
        pollUntilComplete(endpoint).then(({ data }) => {
          expect(data).toBe(mockData);
          expect(mock.history.get).toHaveLength(2);
        }),

        // To ensure the above pollUntilComplete() promise is actually
        // fulfilled, we must explictly run the timers forward by the time
        // indicated in the headers *after* each previous request has been
        // fulfilled.
        axios
          // wait for initial NO_CONTENT response to be fulfilled
          .waitForAll()
          .then(() => {
            jest.advanceTimersByTime(pollInterval);
          }),
      ]));
  });

  describe('given the endpoint returns an error status', () => {
    const errorMessage = 'error message';

    beforeEach(() => {
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_NOT_FOUND, errorMessage);
    });

    it('rejects with the error response', () =>
      pollUntilComplete(endpoint).catch((error) => {
        expect(error.response.data).toBe(errorMessage);
      }));
  });

  describe('given params', () => {
    const params = { foo: 'bar' };
    beforeEach(() => {
      mock.onGet(endpoint, { params }).replyOnce(HTTP_STATUS_OK, mockData);
    });

    it('requests the expected URL', () =>
      pollUntilComplete(endpoint, { params }).then(({ data }) => {
        expect(data).toBe(mockData);
      }));
  });
});
