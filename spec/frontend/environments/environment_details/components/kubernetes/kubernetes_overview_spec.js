import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlEmptyState, GlAlert, GlDrawer } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes/kubernetes_overview.vue';
import KubernetesStatusBar from '~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import { mockPodsTableItems } from 'jest/kubernetes_dashboard/graphql/mock_data';
import { agent, kubernetesNamespace } from '../../../graphql/mock_data';
import { mockKasTunnelUrl, fluxResourceStatus, fluxKustomization } from '../../../mock_data';

Vue.use(VueApollo);

describe('~/environments/environment_details/components/kubernetes/kubernetes_overview.vue', () => {
  let wrapper;

  const defaultProps = {
    environmentName: 'production',
    kubernetesNamespace,
  };

  const provide = {
    kasTunnelUrl: mockKasTunnelUrl,
  };

  const configuration = {
    basePath: provide.kasTunnelUrl.replace(/\/$/, ''),
    headers: {
      'GitLab-Agent-Id': '1',
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    credentials: 'include',
  };

  const kustomizationResourcePath =
    'kustomize.toolkit.fluxcd.io/v1/namespaces/my-namespace/kustomizations/app';

  const fluxKustomizationQuery = jest.fn().mockReturnValue({});
  const fluxHelmReleaseQuery = jest.fn().mockReturnValue({});

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        fluxKustomization: fluxKustomizationQuery,
        fluxHelmRelease: fluxHelmReleaseQuery,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = ({
    clusterAgent = agent,
    fluxResourcePath = kustomizationResourcePath,
    apolloProvider = createApolloProvider(),
  } = {}) => {
    return shallowMount(KubernetesOverview, {
      provide,
      propsData: {
        ...defaultProps,
        clusterAgent,
        fluxResourcePath,
      },
      apolloProvider,
    });
  };

  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesStatusBar = () => wrapper.findComponent(KubernetesStatusBar);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findWorkloadDetails = () => wrapper.findComponent(WorkloadDetails);

  describe('when the agent data is present', () => {
    it('renders kubernetes agent info', () => {
      wrapper = createWrapper();

      expect(findAgentInfo().props('clusterAgent')).toEqual(agent);
    });

    it('renders kubernetes tabs', () => {
      wrapper = createWrapper();

      expect(findKubernetesTabs().props()).toMatchObject({
        namespace: kubernetesNamespace,
        configuration,
        value: k8sResourceType.k8sPods,
        fluxKustomization: {},
      });
    });

    it('renders kubernetes status bar', () => {
      wrapper = createWrapper();

      expect(findKubernetesStatusBar().props()).toEqual({
        clusterHealthStatus: 'success',
        configuration,
        environmentName: defaultProps.environmentName,
        fluxResourcePath: kustomizationResourcePath,
        namespace: kubernetesNamespace,
        resourceType: k8sResourceType.k8sPods,
        fluxApiError: '',
        fluxResourceStatus: [],
      });
    });

    describe('Kubernetes health status', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it("doesn't set `clusterHealthStatus` when pods are still loading", async () => {
        findKubernetesTabs().vm.$emit('loading', true);
        await nextTick();

        expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('');
      });

      it('sets `clusterHealthStatus` as error when pods emitted a failure', async () => {
        findKubernetesTabs().vm.$emit('update-failed-state', { pods: true });
        await nextTick();

        expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');
      });

      it('sets `clusterHealthStatus` as success when data is loaded and no failures where emitted', () => {
        expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('success');
      });

      it('sets `clusterHealthStatus` as success after state update if there are no failures', async () => {
        findKubernetesTabs().vm.$emit('update-failed-state', { pods: true });
        await nextTick();
        expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');

        findKubernetesTabs().vm.$emit('update-failed-state', { pods: false });
        await nextTick();
        expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('success');
      });
    });

    describe('Flux resource', () => {
      describe('when no flux resource path is provided', () => {
        beforeEach(() => {
          wrapper = createWrapper({ fluxResourcePath: '' });
        });

        it("doesn't request Kustomizations and HelmReleases", () => {
          expect(fluxKustomizationQuery).not.toHaveBeenCalled();
          expect(fluxHelmReleaseQuery).not.toHaveBeenCalled();
        });

        it('provides empty `fluxResourceStatus` to KubernetesStatusBar', () => {
          expect(findKubernetesStatusBar().props('fluxResourceStatus')).toEqual([]);
        });

        it('provides empty `fluxKustomization` to KubernetesTabs', () => {
          expect(findKubernetesTabs().props('fluxKustomization')).toEqual({});
        });
      });

      describe('when flux resource path is provided', () => {
        describe('if the provided resource is a Kustomization', () => {
          beforeEach(() => {
            wrapper = createWrapper({ fluxResourcePath: kustomizationResourcePath });
          });

          it('requests the Kustomization resource status', () => {
            expect(fluxKustomizationQuery).toHaveBeenCalledWith(
              {},
              expect.objectContaining({
                configuration,
                fluxResourcePath: kustomizationResourcePath,
              }),
              expect.any(Object),
              expect.any(Object),
            );
          });

          it("doesn't request HelmRelease resource status", () => {
            expect(fluxHelmReleaseQuery).not.toHaveBeenCalled();
          });
        });

        describe('if the provided resource is a helmRelease', () => {
          const helmResourcePath =
            'helm.toolkit.fluxcd.io/v2beta1/namespaces/my-namespace/helmreleases/app';

          beforeEach(() => {
            createWrapper({ fluxResourcePath: helmResourcePath });
          });

          it('requests the HelmRelease resource status', () => {
            expect(fluxHelmReleaseQuery).toHaveBeenCalledWith(
              {},
              expect.objectContaining({
                configuration,
                fluxResourcePath: helmResourcePath,
              }),
              expect.any(Object),
              expect.any(Object),
            );
          });

          it("doesn't request Kustomization resource status", () => {
            expect(fluxKustomizationQuery).not.toHaveBeenCalled();
          });
        });

        describe('with Flux Kustomizations available', () => {
          const createApolloProviderWithKustomizations = () => {
            const mockResolvers = {
              Query: {
                fluxKustomization: jest.fn().mockReturnValue(fluxKustomization),
                fluxHelmRelease: fluxHelmReleaseQuery,
              },
            };

            return createMockApollo([], mockResolvers);
          };

          beforeEach(async () => {
            wrapper = createWrapper({
              apolloProvider: createApolloProviderWithKustomizations(),
            });
            await waitForPromises();
          });
          it('provides correct `fluxResourceStatus` to KubernetesStatusBar', () => {
            expect(findKubernetesStatusBar().props('fluxResourceStatus')).toEqual(
              fluxResourceStatus,
            );
          });

          it('provides correct `fluxKustomization` to KubernetesTabs', () => {
            expect(findKubernetesTabs().props('fluxKustomization')).toEqual(fluxKustomization);
          });
        });

        describe('when Flux API errored', () => {
          const error = new Error('Error from the cluster_client API');
          const createApolloProviderWithErrors = () => {
            const mockResolvers = {
              Query: {
                fluxKustomization: jest.fn().mockRejectedValueOnce(error),
                fluxHelmRelease: jest.fn().mockRejectedValueOnce(error),
              },
            };

            return createMockApollo([], mockResolvers);
          };

          beforeEach(async () => {
            wrapper = createWrapper({
              apolloProvider: createApolloProviderWithErrors(),
              fluxResourcePath:
                'kustomize.toolkit.fluxcd.io/v1/namespaces/my-namespace/kustomizations/app',
            });
            await waitForPromises();
          });

          it('provides api error to KubernetesStatusBar', () => {
            expect(findKubernetesStatusBar().props('fluxApiError')).toEqual(error.message);
          });
        });
      });
    });

    describe('resource details drawer', () => {
      it('is closed by default', () => {
        wrapper = createWrapper();

        expect(findDrawer().props('open')).toBe(false);
      });

      describe('when receives show-resource-details event from the tabs', () => {
        beforeEach(() => {
          wrapper = createWrapper();
          findKubernetesTabs().vm.$emit('show-resource-details', mockPodsTableItems[0]);
        });

        it('opens the drawer', () => {
          expect(findDrawer().props('open')).toBe(true);
        });

        it('provides the resource details to the drawer', () => {
          expect(findWorkloadDetails().props('item')).toEqual(mockPodsTableItems[0]);
        });

        it('renders a title with the selected item name', () => {
          expect(findDrawer().text()).toContain(mockPodsTableItems[0].name);
        });

        it('is closed when clicked on a cross button', async () => {
          expect(findDrawer().props('open')).toBe(true);

          await findDrawer().vm.$emit('close');
          expect(findDrawer().props('open')).toBe(false);
        });

        it('is closed on remove-selection event', async () => {
          expect(findDrawer().props('open')).toBe(true);

          await findKubernetesTabs().vm.$emit('remove-selection');
          expect(findDrawer().props('open')).toBe(false);
        });
      });

      describe('when receives show-flux-resource-details event from the status bar', () => {
        beforeEach(async () => {
          const createApolloProviderWithKustomizations = () => {
            const mockResolvers = {
              Query: {
                fluxKustomization: jest.fn().mockReturnValue(fluxKustomization),
                fluxHelmRelease: fluxHelmReleaseQuery,
              },
            };

            return createMockApollo([], mockResolvers);
          };
          wrapper = createWrapper({
            fluxResourcePath: kustomizationResourcePath,
            apolloProvider: createApolloProviderWithKustomizations(),
          });
          await waitForPromises();

          findKubernetesStatusBar().vm.$emit('show-flux-resource-details', fluxKustomization);
        });

        it('opens the drawer when gets selected item', () => {
          expect(findDrawer().props('open')).toBe(true);
        });

        it('provides the resource details to the drawer', () => {
          const selectedItem = {
            name: fluxKustomization.metadata.name,
            status: 'reconciled',
            labels: fluxKustomization.metadata.labels,
            annotations: fluxKustomization.metadata.annotations,
            kind: fluxKustomization.kind,
            spec: fluxKustomization.spec,
            fullStatus: fluxKustomization.status.conditions,
          };
          expect(findWorkloadDetails().props('item')).toEqual(selectedItem);
        });

        it('renders a title with the selected item name', () => {
          expect(findDrawer().text()).toContain(fluxKustomization.metadata.name);
        });
      });
    });

    describe('on child component error', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it.each([
        [findKubernetesTabs, 'cluster-error'],
        [findKubernetesStatusBar, 'error'],
      ])('shows alert with the error message', async (findFunc, emittedError) => {
        const error = 'Error message from pods';

        findFunc().vm.$emit(emittedError, error);
        await nextTick();

        expect(findAlert().text()).toBe(error);
      });
    });
  });

  describe('when there is no cluster agent data', () => {
    beforeEach(() => {
      wrapper = createWrapper({ clusterAgent: null, fluxResourcePath: '' });
    });

    it('renders empty state component', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'No Kubernetes clusters configured',
        primaryButtonText: 'Get started',
        primaryButtonLink: '/help/ci/environments/kubernetes_dashboard',
      });
    });

    it("doesn't render Kubernetes related components", () => {
      expect(findAgentInfo().exists()).toBe(false);
      expect(findKubernetesStatusBar().exists()).toBe(false);
      expect(findKubernetesTabs().exists()).toBe(false);
    });
  });
});
