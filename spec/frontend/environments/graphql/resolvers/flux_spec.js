import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import { resolvers } from '~/environments/graphql/resolvers';
import { fluxKustomizationsMock } from '../mock_data';

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;

  const configuration = {
    basePath: 'kas-proxy/',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };
  const namespace = 'default';
  const environmentName = 'my-environment';

  beforeEach(() => {
    mockResolvers = resolvers();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('fluxKustomizationStatus', () => {
    const endpoint = `${configuration.basePath}/apis/kustomize.toolkit.fluxcd.io/v1beta1/namespaces/${namespace}/kustomizations/${environmentName}`;
    const fluxResourcePath =
      'kustomize.toolkit.fluxcd.io/v1beta1/namespaces/my-namespace/kustomizations/app';
    const endpointWithFluxResourcePath = `${configuration.basePath}/apis/${fluxResourcePath}`;

    it('should request Flux Kustomizations for the provided namespace via the Kubernetes API if the fluxResourcePath is not specified', async () => {
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.baseOptions.headers })
        .reply(HTTP_STATUS_OK, {
          status: { conditions: fluxKustomizationsMock },
        });

      const fluxKustomizationStatus = await mockResolvers.Query.fluxKustomizationStatus(null, {
        configuration,
        namespace,
        environmentName,
      });

      expect(fluxKustomizationStatus).toEqual(fluxKustomizationsMock);
    });
    it('should request Flux Kustomization for the provided fluxResourcePath via the Kubernetes API', async () => {
      mock
        .onGet(endpointWithFluxResourcePath, {
          withCredentials: true,
          headers: configuration.baseOptions.headers,
        })
        .reply(HTTP_STATUS_OK, {
          status: { conditions: fluxKustomizationsMock },
        });

      const fluxKustomizationStatus = await mockResolvers.Query.fluxKustomizationStatus(null, {
        configuration,
        namespace,
        environmentName,
        fluxResourcePath,
      });

      expect(fluxKustomizationStatus).toEqual(fluxKustomizationsMock);
    });
    it('should throw an error if the API call fails', async () => {
      const apiError = 'Invalid credentials';
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.base })
        .reply(HTTP_STATUS_UNAUTHORIZED, { message: apiError });

      const fluxKustomizationsError = mockResolvers.Query.fluxKustomizationStatus(null, {
        configuration,
        namespace,
        environmentName,
      });

      await expect(fluxKustomizationsError).rejects.toThrow(apiError);
    });
  });

  describe('fluxHelmReleaseStatus', () => {
    const endpoint = `${configuration.basePath}/apis/helm.toolkit.fluxcd.io/v2beta1/namespaces/${namespace}/helmreleases/${environmentName}`;
    const fluxResourcePath =
      'helm.toolkit.fluxcd.io/v2beta1/namespaces/my-namespace/helmreleases/app';
    const endpointWithFluxResourcePath = `${configuration.basePath}/apis/${fluxResourcePath}`;

    it('should request Flux Helm Releases via the Kubernetes API', async () => {
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.baseOptions.headers })
        .reply(HTTP_STATUS_OK, {
          status: { conditions: fluxKustomizationsMock },
        });

      const fluxHelmReleaseStatus = await mockResolvers.Query.fluxHelmReleaseStatus(null, {
        configuration,
        namespace,
        environmentName,
      });

      expect(fluxHelmReleaseStatus).toEqual(fluxKustomizationsMock);
    });
    it('should request Flux HelmRelease for the provided fluxResourcePath via the Kubernetes API', async () => {
      mock
        .onGet(endpointWithFluxResourcePath, {
          withCredentials: true,
          headers: configuration.baseOptions.headers,
        })
        .reply(HTTP_STATUS_OK, {
          status: { conditions: fluxKustomizationsMock },
        });

      const fluxHelmReleaseStatus = await mockResolvers.Query.fluxHelmReleaseStatus(null, {
        configuration,
        namespace,
        environmentName,
        fluxResourcePath,
      });

      expect(fluxHelmReleaseStatus).toEqual(fluxKustomizationsMock);
    });
    it('should throw an error if the API call fails', async () => {
      const apiError = 'Invalid credentials';
      mock
        .onGet(endpoint, { withCredentials: true, headers: configuration.base })
        .reply(HTTP_STATUS_UNAUTHORIZED, { message: apiError });

      const fluxHelmReleasesError = mockResolvers.Query.fluxHelmReleaseStatus(null, {
        configuration,
        namespace,
        environmentName,
      });

      await expect(fluxHelmReleasesError).rejects.toThrow(apiError);
    });
  });
});
