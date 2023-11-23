import { CoreV1Api } from '@gitlab/cluster-client';
import { resolvers } from '~/kubernetes_dashboard/graphql/resolvers';
import { k8sPodsMock } from '../mock_data';

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;

  const configuration = {
    basePath: 'kas-proxy/',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  beforeEach(() => {
    mockResolvers = resolvers;
  });

  describe('k8sPods', () => {
    const client = { writeQuery: jest.fn() };
    const mockPodsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        items: k8sPodsMock,
      });
    });

    const mockAllPodsListFn = jest.fn().mockImplementation(mockPodsListFn);

    beforeEach(() => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockImplementation(mockAllPodsListFn);
    });

    it('should request all pods from the cluster_client library', async () => {
      const pods = await mockResolvers.Query.k8sPods(
        null,
        {
          configuration,
        },
        { client },
      );

      expect(mockAllPodsListFn).toHaveBeenCalled();

      expect(pods).toEqual(k8sPodsMock);
    });
    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(
        mockResolvers.Query.k8sPods(null, { configuration }, { client }),
      ).rejects.toThrow('API error');
    });
  });
});
