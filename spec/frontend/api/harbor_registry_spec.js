import MockAdapter from 'axios-mock-adapter';
import * as harborRegistryApi from '~/api/harbor_registry';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('~/api/harbor_registry', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(axios, 'get');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('getHarborRepositoriesList', () => {
    it('fetches the harbor repositories of the configured harbor project', () => {
      const requestPath = '/flightjs/Flight/-/harbor/repositories';
      const expectedUrl = `${requestPath}.json`;
      const expectedParams = {
        limit: 10,
        page: 1,
        sort: 'update_time desc',
        requestPath,
      };
      const expectResponse = [
        {
          harbor_id: 1,
          name: 'test-project/image-1',
          artifact_count: 1,
          creation_time: '2022-07-16T08:20:34.851Z',
          update_time: '2022-07-16T08:20:34.851Z',
          harbor_project_id: 2,
          pull_count: 0,
          location: 'http://demo.harbor.com/harbor/projects/2/repositories/image-1',
        },
      ];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectResponse);

      return harborRegistryApi.getHarborRepositoriesList(expectedParams).then(({ data }) => {
        expect(data).toEqual(expectResponse);
      });
    });
  });

  describe('getHarborArtifacts', () => {
    it('fetches the artifacts of a particular harbor repository', () => {
      const requestPath = '/flightjs/Flight/-/harbor/repositories';
      const repoName = 'image-1';
      const expectedUrl = `${requestPath}/${repoName}/artifacts.json`;
      const expectedParams = {
        limit: 10,
        page: 1,
        sort: 'name asc',
        repoName,
        requestPath,
      };
      const expectResponse = [
        {
          harbor_id: 1,
          digest: 'sha256:dcdf379c574e1773d703f0c0d56d67594e7a91d6b84d11ff46799f60fb081c52',
          size: 775241,
          push_time: '2022-07-16T08:20:34.867Z',
          tags: ['v2', 'v1', 'latest'],
        },
      ];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectResponse);

      return harborRegistryApi.getHarborArtifacts(expectedParams).then(({ data }) => {
        expect(data).toEqual(expectResponse);
      });
    });
  });

  describe('getHarborTags', () => {
    it('fetches the tags of a particular artifact', () => {
      const requestPath = '/flightjs/Flight/-/harbor/repositories';
      const repoName = 'image-1';
      const digest = 'sha256:5d98daa36cdc8d6c7ed6579ce17230f0f9fd893a9012fc069cb7d714c0e3df35';
      const expectedUrl = `${requestPath}/${repoName}/artifacts/${digest}/tags.json`;
      const expectedParams = {
        requestPath,
        digest,
        repoName,
      };
      const expectResponse = [
        {
          repositoryId: 4,
          artifactId: 5,
          id: 4,
          name: 'latest',
          pullTime: '0001-01-01T00:00:00.000Z',
          pushTime: '2022-05-27T18:21:27.903Z',
          signed: false,
          immutable: false,
        },
      ];
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, expectResponse);

      return harborRegistryApi.getHarborTags(expectedParams).then(({ data }) => {
        expect(data).toEqual(expectResponse);
      });
    });
  });
});
