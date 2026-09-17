import MockAdapter from 'axios-mock-adapter';
import {
  getAdminSshCertificates,
  createAdminSshCertificate,
} from '~/api/admin_ssh_certificates_api';
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_CREATED, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/admin_ssh_certificates_api', () => {
  const expectedUrl = '/api/v4/admin/ssh_certificates';
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getAdminSshCertificates', () => {
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

  describe('createAdminSshCertificate', () => {
    it('posts the title and key', async () => {
      const params = {
        title: 'Production CA',
        key: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample',
      };
      mock.onPost(expectedUrl).reply(HTTP_STATUS_CREATED, {});

      await createAdminSshCertificate(params);

      expect(mock.history.post[0].url).toBe(expectedUrl);
      expect(JSON.parse(mock.history.post[0].data)).toEqual(params);
    });
  });
});
