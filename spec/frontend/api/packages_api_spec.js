import MockAdapter from 'axios-mock-adapter';
import { deleteDependencyProxyCacheList, publishPackage } from '~/api/packages_api';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_ACCEPTED, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Api', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = {
      api_version: dummyApiVersion,
      relative_url_root: dummyUrlRoot,
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('packages', () => {
    const projectPath = 'project_a';
    const name = 'foo';
    const packageVersion = '0';
    const apiResponse = [{ id: 1, name: 'foo' }];

    describe('publishPackage', () => {
      it('publishes the package', () => {
        const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${projectPath}/packages/generic/${name}/${packageVersion}/${name}`;

        jest.spyOn(axios, 'put');
        mock.onPut(expectedUrl).replyOnce(HTTP_STATUS_OK, apiResponse);

        return publishPackage(
          {
            projectPath,
            name,
            version: 0,
            fileName: name,
            files: [new File(['zip contents'], 'bar.zip')],
          },
          { status: 'hidden', select: 'package_file' },
        ).then(({ data }) => {
          expect(data).toEqual(apiResponse);
          expect(axios.put).toHaveBeenCalledWith(expectedUrl, expect.any(File), {
            params: { select: 'package_file', status: 'hidden' },
          });
        });
      });
    });
  });

  describe('deleteDependencyProxyCacheList', () => {
    it('schedules the cache list for deletion', async () => {
      const groupId = 1;
      const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/groups/${groupId}/dependency_proxy/cache`;

      mock.onDelete(expectedUrl).reply(HTTP_STATUS_ACCEPTED);
      const { status } = await deleteDependencyProxyCacheList(groupId, {});

      expect(status).toBe(HTTP_STATUS_ACCEPTED);
    });
  });
});
