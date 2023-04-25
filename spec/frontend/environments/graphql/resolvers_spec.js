import MockAdapter from 'axios-mock-adapter';
import { CoreV1Api } from '@gitlab/cluster-client';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { resolvers } from '~/environments/graphql/resolvers';
import environmentToRollback from '~/environments/graphql/queries/environment_to_rollback.query.graphql';
import environmentToDelete from '~/environments/graphql/queries/environment_to_delete.query.graphql';
import environmentToStopQuery from '~/environments/graphql/queries/environment_to_stop.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import pollIntervalQuery from '~/environments/graphql/queries/poll_interval.query.graphql';
import isEnvironmentStoppingQuery from '~/environments/graphql/queries/is_environment_stopping.query.graphql';
import pageInfoQuery from '~/environments/graphql/queries/page_info.query.graphql';
import { TEST_HOST } from 'helpers/test_constants';
import {
  environmentsApp,
  resolvedEnvironmentsApp,
  resolvedEnvironment,
  folder,
  resolvedFolder,
  k8sPodsMock,
  k8sServicesMock,
} from './mock_data';

const ENDPOINT = `${TEST_HOST}/environments`;

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;
  let mockApollo;
  let localState;

  const configuration = {
    basePath: 'kas-proxy/',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  beforeEach(() => {
    mockResolvers = resolvers(ENDPOINT);
    mock = new MockAdapter(axios);
    mockApollo = createMockApollo();
    localState = mockApollo.defaultClient.localState;
  });

  afterEach(() => {
    mock.reset();
  });

  describe('environmentApp', () => {
    it('should fetch environments and map them to frontend data', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'available';
      const search = '';
      mock
        .onGet(ENDPOINT, { params: { nested: true, scope, page: 1, search } })
        .reply(HTTP_STATUS_OK, environmentsApp, {});

      const app = await mockResolvers.Query.environmentApp(
        null,
        { scope, page: 1, search },
        { cache },
      );
      expect(app).toEqual(resolvedEnvironmentsApp);
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pollIntervalQuery,
        data: { interval: undefined },
      });
    });
    it('should set the poll interval when there is one', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'stopped';
      const interval = 3000;
      mock
        .onGet(ENDPOINT, { params: { nested: true, scope, page: 1, search: '' } })
        .reply(HTTP_STATUS_OK, environmentsApp, {
          'poll-interval': interval,
        });

      await mockResolvers.Query.environmentApp(null, { scope, page: 1, search: '' }, { cache });
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pollIntervalQuery,
        data: { interval },
      });
    });
    it('should set page info if there is any', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'stopped';
      mock
        .onGet(ENDPOINT, { params: { nested: true, scope, page: 1, search: '' } })
        .reply(HTTP_STATUS_OK, environmentsApp, {
          'x-next-page': '2',
          'x-page': '1',
          'X-Per-Page': '2',
          'X-Prev-Page': '',
          'X-TOTAL': '37',
          'X-Total-Pages': '5',
        });

      await mockResolvers.Query.environmentApp(null, { scope, page: 1, search: '' }, { cache });
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pageInfoQuery,
        data: {
          pageInfo: {
            total: 37,
            perPage: 2,
            previousPage: NaN,
            totalPages: 5,
            nextPage: 2,
            page: 1,
            __typename: 'LocalPageInfo',
          },
        },
      });
    });
    it('should not set page info if there is none', async () => {
      const cache = { writeQuery: jest.fn() };
      const scope = 'stopped';
      mock
        .onGet(ENDPOINT, { params: { nested: true, scope, page: 1, search: '' } })
        .reply(HTTP_STATUS_OK, environmentsApp, {});

      await mockResolvers.Query.environmentApp(null, { scope, page: 1, search: '' }, { cache });
      expect(cache.writeQuery).toHaveBeenCalledWith({
        query: pageInfoQuery,
        data: {
          pageInfo: {
            __typename: 'LocalPageInfo',
            nextPage: NaN,
            page: NaN,
            perPage: NaN,
            previousPage: NaN,
            total: NaN,
            totalPages: NaN,
          },
        },
      });
    });
  });
  describe('folder', () => {
    it('should fetch the folder url passed to it', async () => {
      mock
        .onGet(ENDPOINT, { params: { per_page: 3, scope: 'available', search: '' } })
        .reply(HTTP_STATUS_OK, folder);

      const environmentFolder = await mockResolvers.Query.folder(null, {
        environment: { folderPath: ENDPOINT },
        scope: 'available',
        search: '',
      });

      expect(environmentFolder).toEqual(resolvedFolder);
    });
  });
  describe('k8sPods', () => {
    const namespace = 'default';

    const mockPodsListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        data: {
          items: k8sPodsMock,
        },
      });
    });

    const mockNamespacedPodsListFn = jest.fn().mockImplementation(mockPodsListFn);
    const mockAllPodsListFn = jest.fn().mockImplementation(mockPodsListFn);

    beforeEach(() => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1NamespacedPod')
        .mockImplementation(mockNamespacedPodsListFn);
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockImplementation(mockAllPodsListFn);
    });

    it('should request namespaced pods from the cluster_client library if namespace is specified', async () => {
      const pods = await mockResolvers.Query.k8sPods(null, { configuration, namespace });

      expect(mockNamespacedPodsListFn).toHaveBeenCalledWith(namespace);
      expect(mockAllPodsListFn).not.toHaveBeenCalled();

      expect(pods).toEqual(k8sPodsMock);
    });
    it('should request all pods from the cluster_client library if namespace is not specified', async () => {
      const pods = await mockResolvers.Query.k8sPods(null, { configuration, namespace: '' });

      expect(mockAllPodsListFn).toHaveBeenCalled();
      expect(mockNamespacedPodsListFn).not.toHaveBeenCalled();

      expect(pods).toEqual(k8sPodsMock);
    });
    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1PodForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(mockResolvers.Query.k8sPods(null, { configuration })).rejects.toThrow(
        'API error',
      );
    });
  });
  describe('k8sServices', () => {
    const mockServicesListFn = jest.fn().mockImplementation(() => {
      return Promise.resolve({
        data: {
          items: k8sServicesMock,
        },
      });
    });

    beforeEach(() => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
        .mockImplementation(mockServicesListFn);
    });

    it('should request services from the cluster_client library', async () => {
      const services = await mockResolvers.Query.k8sServices(null, { configuration });

      expect(mockServicesListFn).toHaveBeenCalled();

      expect(services).toEqual(k8sServicesMock);
    });
    it('should throw an error if the API call fails', async () => {
      jest
        .spyOn(CoreV1Api.prototype, 'listCoreV1ServiceForAllNamespaces')
        .mockRejectedValue(new Error('API error'));

      await expect(mockResolvers.Query.k8sServices(null, { configuration })).rejects.toThrow(
        'API error',
      );
    });
  });
  describe('stopEnvironmentREST', () => {
    it('should post to the stop environment path', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_OK);

      const client = { writeQuery: jest.fn() };
      const environment = { stopPath: ENDPOINT };
      await mockResolvers.Mutation.stopEnvironmentREST(null, { environment }, { client });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: isEnvironmentStoppingQuery,
        variables: { environment },
        data: { isEnvironmentStopping: true },
      });
    });
    it('should set is stopping to false if stop fails', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      const client = { writeQuery: jest.fn() };
      const environment = { stopPath: ENDPOINT };
      await mockResolvers.Mutation.stopEnvironmentREST(null, { environment }, { client });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: isEnvironmentStoppingQuery,
        variables: { environment },
        data: { isEnvironmentStopping: false },
      });
    });
  });
  describe('rollbackEnvironment', () => {
    it('should post to the retry environment path', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_OK);

      await mockResolvers.Mutation.rollbackEnvironment(null, {
        environment: { retryUrl: ENDPOINT },
      });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('deleteEnvironment', () => {
    it('should DELETE to the delete environment path', async () => {
      mock.onDelete(ENDPOINT).reply(HTTP_STATUS_OK);

      await mockResolvers.Mutation.deleteEnvironment(null, {
        environment: { deletePath: ENDPOINT },
      });

      expect(mock.history.delete).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'delete' }),
      );
    });
  });
  describe('cancelAutoStop', () => {
    it('should post to the auto stop path', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_OK);

      await mockResolvers.Mutation.cancelAutoStop(null, { autoStopUrl: ENDPOINT });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('setEnvironmentToRollback', () => {
    it('should write the given environment to the cache', () => {
      localState.client.writeQuery = jest.fn();
      mockResolvers.Mutation.setEnvironmentToRollback(
        null,
        { environment: resolvedEnvironment },
        localState,
      );

      expect(localState.client.writeQuery).toHaveBeenCalledWith({
        query: environmentToRollback,
        data: { environmentToRollback: resolvedEnvironment },
      });
    });
  });
  describe('setEnvironmentToDelete', () => {
    it('should write the given environment to the cache', () => {
      localState.client.writeQuery = jest.fn();
      mockResolvers.Mutation.setEnvironmentToDelete(
        null,
        { environment: resolvedEnvironment },
        localState,
      );

      expect(localState.client.writeQuery).toHaveBeenCalledWith({
        query: environmentToDelete,
        data: { environmentToDelete: resolvedEnvironment },
      });
    });
  });
  describe('setEnvironmentToStop', () => {
    it('should write the given environment to the cache', () => {
      localState.client.writeQuery = jest.fn();
      mockResolvers.Mutation.setEnvironmentToStop(
        null,
        { environment: resolvedEnvironment },
        localState,
      );

      expect(localState.client.writeQuery).toHaveBeenCalledWith({
        query: environmentToStopQuery,
        data: { environmentToStop: resolvedEnvironment },
      });
    });
  });
  describe('action', () => {
    it('should POST to the given path', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_OK);
      const errors = await mockResolvers.Mutation.action(null, { action: { playPath: ENDPOINT } });

      expect(errors).toEqual({ __typename: 'LocalEnvironmentErrors', errors: [] });
    });
    it('should return a nice error message on fail', async () => {
      mock.onPost(ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      const errors = await mockResolvers.Mutation.action(null, { action: { playPath: ENDPOINT } });

      expect(errors).toEqual({
        __typename: 'LocalEnvironmentErrors',
        errors: [s__('Environments|An error occurred while making the request.')],
      });
    });
  });
});
