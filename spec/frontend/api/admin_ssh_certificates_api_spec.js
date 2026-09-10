import MockAdapter from 'axios-mock-adapter';
import { getAdminSshCertificates } from '~/api/admin_ssh_certificates_api';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/admin_ssh_certificates_api', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getAdminSshCertificates', () => {
    const expectedUrl = '/api/v4/admin/ssh_certificates';

    it('requests the given page and page size', async () => {
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, []);

      await getAdminSshCertificates({ page: 3, perPage: 10 });

      expect(mock.history.get[0]).toMatchObject({
        url: expectedUrl,
        params: { page: 3, per_page: 10 },
      });
    });

    it('defaults to the first page and the default page size', async () => {
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, []);

      await getAdminSshCertificates();

      expect(mock.history.get[0].params).toEqual({ page: 1, per_page: DEFAULT_PER_PAGE });
    });
  });
});
