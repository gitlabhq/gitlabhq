import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import { backOffRequest } from '~/monitoring/stores/actions';
import statusCodes from '~/lib/utils/http_status';
import { backOff } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils');

const MAX_REQUESTS = 3;

describe('Monitoring store helpers', () => {
  let mock;

  // Mock underlying `backOff` function to remove in-built delay.
  backOff.mockImplementation(
    callback =>
      new Promise((resolve, reject) => {
        const stop = arg => (arg instanceof Error ? reject(arg) : resolve(arg));
        const next = () => callback(next, stop);
        callback(next, stop);
      }),
  );

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('backOffRequest', () => {
    it('returns immediately when recieving a 200 status code', () => {
      mock.onGet(TEST_HOST).reply(200);

      return backOffRequest(() => axios.get(TEST_HOST)).then(() => {
        expect(mock.history.get.length).toBe(1);
      });
    });

    it(`repeats the network call ${MAX_REQUESTS} times when receiving a 204 response`, done => {
      mock.onGet(TEST_HOST).reply(statusCodes.NO_CONTENT, {});

      backOffRequest(() => axios.get(TEST_HOST))
        .then(done.fail)
        .catch(() => {
          expect(mock.history.get.length).toBe(MAX_REQUESTS);
          done();
        });
    });
  });
});
