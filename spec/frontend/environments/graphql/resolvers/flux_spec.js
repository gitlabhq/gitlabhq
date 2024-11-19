import MockAdapter from 'axios-mock-adapter';
import { WatchApi, WebSocketWatchManager } from '@gitlab/cluster-client';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { resolvers } from '~/environments/graphql/resolvers';
import { updateConnectionStatus } from '~/environments/graphql/resolvers/kubernetes/k8s_connection_status';
import {
  connectionStatus,
  k8sResourceType,
} from '~/environments/graphql/resolvers/kubernetes/constants';
import {
  fluxKustomizationMock,
  fluxHelmReleaseMock,
  fluxKustomizationMapped,
  fluxHelmReleaseMapped,
} from '../mock_data';

jest.mock('~/environments/graphql/resolvers/kubernetes/k8s_connection_status');

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;

  const configuration = {
    basePath: 'kas-proxy/',
    headers: { 'GitLab-Agent-Id': '1' },
  };

  beforeEach(() => {
    mockResolvers = resolvers();
    mock = new MockAdapter(axios);
    gon.features = {
      useWebsocketForK8sWatch: false,
    };
  });

  afterEach(() => {
    mock.reset();
  });

  describe('fluxKustomization', () => {
    const client = { writeQuery: jest.fn() };
    const fluxResourcePath =
      'kustomize.toolkit.fluxcd.io/v1/namespaces/my-namespace/kustomizations/app';
    const endpoint = `${configuration.basePath}/apis/${fluxResourcePath}`;

    const mockWatcher = WatchApi.prototype;
    const mockKustomizationStatusFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });
    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([fluxKustomizationMock]);
      }
    });
    const resourceName = 'custom-resource';
    const resourceNamespace = 'custom-namespace';
    const apiVersion = 'kustomize.toolkit.fluxcd.io/v1';

    beforeEach(() => {
      jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockKustomizationStatusFn);
      jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
    });

    describe('when the Kustomization data is present', () => {
      beforeEach(() => {
        mock
          .onGet(endpoint, { withCredentials: true, headers: configuration.headers })
          .reply(HTTP_STATUS_OK, {
            apiVersion,
            ...fluxKustomizationMock,
          });
      });
      it('should watch Kustomization by the metadata name from the cluster_client library when the data is present', async () => {
        await mockResolvers.Query.fluxKustomization(
          null,
          {
            configuration,
            fluxResourcePath,
          },
          { client },
        );

        expect(mockKustomizationStatusFn).toHaveBeenCalledWith(
          `/apis/${apiVersion}/namespaces/${resourceNamespace}/kustomizations`,
          {
            watch: true,
            fieldSelector: `metadata.name=${decodeURIComponent(resourceName)}`,
          },
        );
        expect(updateConnectionStatus).toHaveBeenCalledWith(expect.anything(), {
          configuration,
          namespace: resourceNamespace,
          resourceType: k8sResourceType.fluxKustomizations,
          status: connectionStatus.connecting,
        });
      });

      it('should return data when received from the library', async () => {
        const kustomizationStatus = await mockResolvers.Query.fluxKustomization(
          null,
          {
            configuration,
            fluxResourcePath,
          },
          { client },
        );

        expect(kustomizationStatus).toEqual(fluxKustomizationMapped);
      });

      describe('when `useWebsocketForK8sWatch` feature is enabled', () => {
        const mockWebsocketManager = WebSocketWatchManager.prototype;
        const mockInitConnectionFn = jest.fn().mockImplementation(() => {
          return Promise.resolve(mockWebsocketManager);
        });

        beforeEach(() => {
          gon.features = {
            useWebsocketForK8sWatch: true,
          };

          jest
            .spyOn(mockWebsocketManager, 'initConnection')
            .mockImplementation(mockInitConnectionFn);
          jest.spyOn(mockWebsocketManager, 'on').mockImplementation(jest.fn());
        });

        it('calls websocket API', async () => {
          await mockResolvers.Query.fluxKustomization(
            null,
            {
              configuration,
              fluxResourcePath,
            },
            { client },
          );

          expect(mockInitConnectionFn).toHaveBeenCalledWith({
            configuration,
            message: {
              watchId: `kustomizations-${resourceName}`,
              watchParams: {
                fieldSelector: `metadata.name=${resourceName}`,
                group: 'kustomize.toolkit.fluxcd.io',
                namespace: resourceNamespace,
                resource: 'kustomizations',
                version: 'v1',
              },
            },
          });
        });

        it("doesn't call watch API", async () => {
          await mockResolvers.Query.fluxKustomization(
            null,
            {
              configuration,
              fluxResourcePath,
            },
            { client },
          );
          expect(mockKustomizationStatusFn).not.toHaveBeenCalled();
        });
      });
    });

    it('should not watch Kustomization by the metadata name from the cluster_client library when the data is not present', async () => {
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.headers })
        .reply(HTTP_STATUS_OK, {});

      await mockResolvers.Query.fluxKustomization(
        null,
        {
          configuration,
          fluxResourcePath,
        },
        { client },
      );

      expect(mockKustomizationStatusFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      const apiError = 'Invalid credentials';
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.base })
        .reply(HTTP_STATUS_UNAUTHORIZED, { message: apiError });

      const fluxKustomizationsError = mockResolvers.Query.fluxKustomization(
        null,
        {
          configuration,
          fluxResourcePath,
        },
        { client },
      );

      await expect(fluxKustomizationsError).rejects.toThrow(apiError);
    });
  });

  describe('fluxHelmRelease', () => {
    const client = { writeQuery: jest.fn() };
    const fluxResourcePath =
      'helm.toolkit.fluxcd.io/v2beta1/namespaces/my-namespace/helmreleases/app';
    const endpoint = `${configuration.basePath}/apis/${fluxResourcePath}`;

    const mockWatcher = WatchApi.prototype;
    const mockHelmReleaseStatusFn = jest.fn().mockImplementation(() => {
      return Promise.resolve(mockWatcher);
    });
    const mockOnDataFn = jest.fn().mockImplementation((eventName, callback) => {
      if (eventName === 'data') {
        callback([fluxHelmReleaseMock]);
      }
    });
    const resourceName = 'custom-resource';
    const resourceNamespace = 'custom-namespace';
    const apiVersion = 'helm.toolkit.fluxcd.io/v2beta1';

    beforeEach(() => {
      jest.spyOn(mockWatcher, 'subscribeToStream').mockImplementation(mockHelmReleaseStatusFn);
      jest.spyOn(mockWatcher, 'on').mockImplementation(mockOnDataFn);
    });

    describe('when the HelmRelease data is present', () => {
      beforeEach(() => {
        mock
          .onGet(endpoint, { withCredentials: true, headers: configuration.headers })
          .reply(HTTP_STATUS_OK, {
            apiVersion,
            ...fluxHelmReleaseMock,
          });
      });
      it('should watch HelmRelease by the metadata name from the cluster_client library when the data is present', async () => {
        await mockResolvers.Query.fluxHelmRelease(
          null,
          {
            configuration,
            fluxResourcePath,
          },
          { client },
        );

        expect(mockHelmReleaseStatusFn).toHaveBeenCalledWith(
          `/apis/${apiVersion}/namespaces/${resourceNamespace}/helmreleases`,
          {
            watch: true,
            fieldSelector: `metadata.name=${decodeURIComponent(resourceName)}`,
          },
        );
      });

      it('should return data when received from the library', async () => {
        const fluxHelmRelease = await mockResolvers.Query.fluxHelmRelease(
          null,
          {
            configuration,
            fluxResourcePath,
          },
          { client },
        );

        expect(fluxHelmRelease).toEqual(fluxHelmReleaseMapped);
      });
    });

    it('should not watch Kustomization by the metadata name from the cluster_client library when the data is not present', async () => {
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.headers })
        .reply(HTTP_STATUS_OK, {});

      await mockResolvers.Query.fluxHelmRelease(
        null,
        {
          configuration,
          fluxResourcePath,
        },
        { client },
      );

      expect(mockHelmReleaseStatusFn).not.toHaveBeenCalled();
    });

    it('should throw an error if the API call fails', async () => {
      const apiError = 'Invalid credentials';
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.base })
        .reply(HTTP_STATUS_UNAUTHORIZED, { message: apiError });

      const fluxHelmReleasesError = mockResolvers.Query.fluxHelmRelease(
        null,
        {
          configuration,
          fluxResourcePath,
        },
        { client },
      );

      await expect(fluxHelmReleasesError).rejects.toThrow(apiError);
    });
  });

  describe('updateFluxResource', () => {
    const fluxResourcePath =
      'kustomize.toolkit.fluxcd.io/v1/namespaces/my-namespace/kustomizations/app';
    const endpoint = `${configuration.basePath}/apis/${fluxResourcePath}`;

    const body = JSON.stringify([
      {
        op: 'replace',
        path: '/metadata/annotations/reconcile.fluxcd.io~1requestedAt',
        value: new Date(),
      },
    ]);

    it('should request update flux resource API', async () => {
      mock.onPatch(endpoint).reply(HTTP_STATUS_OK);

      const result = await mockResolvers.Mutation.updateFluxResource(null, {
        configuration,
        fluxResourcePath,
        data: body,
      });

      expect(result).toEqual({
        __typename: 'LocalKubernetesErrors',
        errors: [],
      });
    });

    it('should return errors array if the API call fails', async () => {
      mock.onPatch(endpoint).reply(HTTP_STATUS_UNAUTHORIZED, { message: 'not authorized' });

      const result = await mockResolvers.Mutation.updateFluxResource(null, {
        configuration,
        fluxResourcePath,
        data: body,
      });

      expect(result).toEqual({
        __typename: 'LocalKubernetesErrors',
        errors: ['not authorized'],
      });
    });
  });
});
