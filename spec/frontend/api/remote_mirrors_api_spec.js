import MockAdapter from 'axios-mock-adapter';
import { deleteRemoteMirror, syncRemoteMirror, updateRemoteMirror } from '~/api/remote_mirrors_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/remote_mirrors_api.js', () => {
  const dummyApiVersion = 'v4';
  const projectId = 7;
  const mirrorId = 42;

  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: dummyApiVersion };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('deleteRemoteMirror', () => {
    it('sends DELETE to the remote mirror endpoint', async () => {
      const expectedUrl = `/api/${dummyApiVersion}/projects/${projectId}/remote_mirrors/${mirrorId}`;
      mock.onDelete(expectedUrl).replyOnce(HTTP_STATUS_OK);

      await deleteRemoteMirror(projectId, mirrorId);

      expect(mock.history.delete).toHaveLength(1);
      expect(mock.history.delete[0].url).toBe(expectedUrl);
    });
  });

  describe('syncRemoteMirror', () => {
    it('sends POST to the remote mirror sync endpoint', async () => {
      const expectedUrl = `/api/${dummyApiVersion}/projects/${projectId}/remote_mirrors/${mirrorId}/sync`;
      mock.onPost(expectedUrl).replyOnce(HTTP_STATUS_OK);

      await syncRemoteMirror(projectId, mirrorId);

      expect(mock.history.post).toHaveLength(1);
      expect(mock.history.post[0].url).toBe(expectedUrl);
    });
  });

  describe('updateRemoteMirror', () => {
    it('sends PUT with data to the remote mirror endpoint', async () => {
      const expectedUrl = `/api/${dummyApiVersion}/projects/${projectId}/remote_mirrors/${mirrorId}`;
      const data = { enabled: true, only_protected_branches: false };
      mock.onPut(expectedUrl).replyOnce(HTTP_STATUS_OK);

      await updateRemoteMirror(projectId, mirrorId, data);

      expect(mock.history.put).toHaveLength(1);
      expect(mock.history.put[0].url).toBe(expectedUrl);
      expect(JSON.parse(mock.history.put[0].data)).toEqual(data);
    });
  });
});
