import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import KubernetesStatusBar from '~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue';
import KubernetesConnectionStatus from '~/environments/environment_details/components/kubernetes/kubernetes_connection_status.vue';
import {
  CLUSTER_HEALTH_SUCCESS,
  CLUSTER_HEALTH_ERROR,
  CLUSTER_STATUS_HEALTHY_TEXT,
  CLUSTER_STATUS_UNHEALTHY_TEXT,
  SYNC_STATUS_BADGES,
} from '~/environments/constants';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import { mockKasTunnelUrl } from '../../../mock_data';
import { kubernetesNamespace } from '../../../graphql/mock_data';

Vue.use(VueApollo);

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
    withCredentials: true,
  },
};
const environmentName = 'environment_name';
const kustomizationResourcePath =
  'kustomize.toolkit.fluxcd.io/v1beta1/namespaces/my-namespace/kustomizations/app';

describe('~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHealthBadge = () => wrapper.findByTestId('health-badge');
  const findSyncBadge = () => wrapper.findByTestId('sync-badge');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findConnectionStatus = () => wrapper.findComponent(KubernetesConnectionStatus);

  const fluxKustomizationStatusQuery = jest.fn().mockReturnValue([]);
  const fluxHelmReleaseStatusQuery = jest.fn().mockReturnValue([]);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        fluxKustomizationStatus: fluxKustomizationStatusQuery,
        fluxHelmReleaseStatus: fluxHelmReleaseStatusQuery,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = ({
    apolloProvider = createApolloProvider(),
    clusterHealthStatus = '',
    fluxResourcePath = '',
    namespace = kubernetesNamespace,
    resourceType = k8sResourceType.k8sPods,
    k8sWatchApi = false,
  } = {}) => {
    wrapper = shallowMountExtended(KubernetesStatusBar, {
      provide: {
        glFeatures: {
          k8sWatchApi,
        },
      },
      propsData: {
        clusterHealthStatus,
        configuration,
        environmentName,
        fluxResourcePath,
        namespace,
        resourceType,
      },
      apolloProvider,
      stubs: { GlSprintf },
    });
  };

  describe('connection status', () => {
    describe('when the k8sWatchApi feature flag is disabled', () => {
      it('doesnt render connection status component', () => {
        createWrapper({ k8sWatchApi: false });
        expect(findConnectionStatus().exists()).toBe(false);
      });
    });
    describe('when the k8sWatchApi feature flag is enabled', () => {
      beforeEach(() => {
        createWrapper({ k8sWatchApi: true });
      });
      it('passes correct props to connection status component', () => {
        const connectionStatus = findConnectionStatus();
        expect(connectionStatus.props('configuration')).toBe(configuration);
        expect(connectionStatus.props('namespace')).toBe(kubernetesNamespace);
        expect(connectionStatus.props('resourceType')).toBe(k8sResourceType.k8sPods);
      });

      it('handles errors from connection status component', () => {
        const connectionStatus = findConnectionStatus();
        const connectionStatusError = new Error('connection status error');
        connectionStatus.vm.$emit('error', connectionStatusError);

        expect(wrapper.emitted('error')).toEqual([[connectionStatusError]]);
      });
    });
  });

  describe('health badge', () => {
    it('shows loading icon when cluster health is not present', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it.each([
      [CLUSTER_HEALTH_SUCCESS, 'success', 'status-success', CLUSTER_STATUS_HEALTHY_TEXT],
      [CLUSTER_HEALTH_ERROR, 'danger', 'status-alert', CLUSTER_STATUS_UNHEALTHY_TEXT],
    ])(
      'when clusterHealthStatus is %s shows health badge with variant %s, icon %s and text %s',
      (status, variant, icon, text) => {
        createWrapper({ clusterHealthStatus: status });

        expect(findLoadingIcon().exists()).toBe(false);
        expect(findHealthBadge().props()).toMatchObject({ variant, icon });
        expect(findHealthBadge().text()).toBe(text);
      },
    );
  });

  describe('sync badge', () => {
    describe('when no flux resource path is provided', () => {
      beforeEach(() => {
        createWrapper();
      });

      it("doesn't request Kustomizations and HelmReleases", () => {
        expect(fluxKustomizationStatusQuery).not.toHaveBeenCalled();
        expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
      });

      it('renders sync status as Unavailable', () => {
        expect(findSyncBadge().text()).toBe('Unavailable');
      });
    });

    describe('when flux resource path is provided', () => {
      let fluxResourcePath;

      describe('if the provided resource is a Kustomization', () => {
        beforeEach(() => {
          fluxResourcePath = kustomizationResourcePath;

          createWrapper({ fluxResourcePath });
        });

        it('requests the Kustomization resource status', () => {
          expect(fluxKustomizationStatusQuery).toHaveBeenCalledWith(
            {},
            expect.objectContaining({
              configuration,
              fluxResourcePath,
            }),
            expect.any(Object),
            expect.any(Object),
          );
        });

        it("doesn't request HelmRelease resource status", () => {
          expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
        });
      });

      describe('if the provided resource is a helmRelease', () => {
        beforeEach(() => {
          fluxResourcePath =
            'helm.toolkit.fluxcd.io/v2beta1/namespaces/my-namespace/helmreleases/app';

          createWrapper({ fluxResourcePath });
        });

        it('requests the HelmRelease resource status', () => {
          expect(fluxHelmReleaseStatusQuery).toHaveBeenCalledWith(
            {},
            expect.objectContaining({
              configuration,
              fluxResourcePath,
            }),
            expect.any(Object),
            expect.any(Object),
          );
        });

        it("doesn't request Kustomization resource status", () => {
          expect(fluxKustomizationStatusQuery).not.toHaveBeenCalled();
        });
      });

      describe('with Flux Kustomizations available', () => {
        const createApolloProviderWithKustomizations = ({
          result = { status: 'True', type: 'Ready', message: '' },
        } = {}) => {
          const mockResolvers = {
            Query: {
              fluxKustomizationStatus: jest.fn().mockReturnValue([result]),
              fluxHelmReleaseStatus: fluxHelmReleaseStatusQuery,
            },
          };

          return createMockApollo([], mockResolvers);
        };

        it("doesn't request HelmReleases when the Kustomizations were found", async () => {
          createWrapper({
            apolloProvider: createApolloProviderWithKustomizations(),
          });
          await waitForPromises();

          expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
        });
      });

      describe('when receives data from the Flux', () => {
        const createApolloProviderWithKustomizations = (result) => {
          const mockResolvers = {
            Query: {
              fluxKustomizationStatus: jest.fn().mockReturnValue([result]),
              fluxHelmReleaseStatus: fluxHelmReleaseStatusQuery,
            },
          };

          return createMockApollo([], mockResolvers);
        };
        const message = 'Message from Flux';

        it.each`
          status       | type             | reason           | statusText       | statusPopover
          ${'True'}    | ${'Stalled'}     | ${''}            | ${'Stalled'}     | ${message}
          ${'True'}    | ${'Reconciling'} | ${''}            | ${'Reconciling'} | ${'Flux sync reconciling'}
          ${'Unknown'} | ${'Ready'}       | ${'Progressing'} | ${'Reconciling'} | ${message}
          ${'True'}    | ${'Ready'}       | ${''}            | ${'Reconciled'}  | ${'Flux sync reconciled successfully'}
          ${'False'}   | ${'Ready'}       | ${''}            | ${'Failed'}      | ${message}
          ${'Unknown'} | ${'Ready'}       | ${''}            | ${'Unknown'}     | ${'Unable to detect state. How are states detected?'}
        `(
          'renders sync status as $statusText when status is $status, type is $type, and reason is $reason',
          async ({ status, type, reason, statusText, statusPopover }) => {
            createWrapper({
              fluxResourcePath: kustomizationResourcePath,
              apolloProvider: createApolloProviderWithKustomizations({
                status,
                type,
                reason,
                message,
              }),
            });
            await waitForPromises();

            expect(findSyncBadge().text()).toBe(statusText);
            expect(findPopover().text()).toBe(statusPopover);
          },
        );
      });

      describe('when Flux API errored', () => {
        const error = new Error('Error from the cluster_client API');
        const createApolloProviderWithErrors = () => {
          const mockResolvers = {
            Query: {
              fluxKustomizationStatus: jest.fn().mockRejectedValueOnce(error),
              fluxHelmReleaseStatus: jest.fn().mockRejectedValueOnce(error),
            },
          };

          return createMockApollo([], mockResolvers);
        };

        beforeEach(async () => {
          createWrapper({
            apolloProvider: createApolloProviderWithErrors(),
            fluxResourcePath:
              'kustomize.toolkit.fluxcd.io/v1beta1/namespaces/my-namespace/kustomizations/app',
          });
          await waitForPromises();
        });

        it('renders sync badge as unavailable', () => {
          const badge = SYNC_STATUS_BADGES.unavailable;

          expect(findSyncBadge().text()).toBe(badge.text);
          expect(findSyncBadge().props()).toMatchObject({
            icon: badge.icon,
            variant: badge.variant,
          });
        });

        it('renders popover with an API error message', () => {
          expect(findPopover().text()).toBe(error.message);
          expect(findPopover().props('title')).toBe('Flux sync status is unavailable');
        });
      });
    });
  });
});
