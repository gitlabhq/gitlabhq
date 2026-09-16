import MockAdapter from 'axios-mock-adapter';
import { getOfflineExports } from '~/api/offline_transfer_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/offline_transfer_api', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
  });

  const exports = [{ id: 1 }, { id: 2 }];

  describe('getOfflineExports', () => {
    const expectedUrl = '/api/v4/offline_exports';

    it('retrieves offline exports from the correct URL', async () => {
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, exports);

      const { data } = await getOfflineExports();

      expect(mock.history.get[0]).toMatchObject({
        url: expectedUrl,
        params: {},
      });
      expect(data).toEqual(exports);
    });
  });
});
