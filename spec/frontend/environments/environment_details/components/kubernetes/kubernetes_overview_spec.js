import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import {
  GlEmptyState,
  GlAlert,
  GlDrawer,
  GlSprintf,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes/kubernetes_overview.vue';
import KubernetesStatusBar from '~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import DeletePodModal from '~/environments/environment_details/components/kubernetes/delete_pod_modal.vue';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import { mockPodsTableItems } from 'jest/kubernetes_dashboard/graphql/mock_data';
import eventHub from '~/environments/event_hub';
import { CONNECT_MODAL_ID } from '~/clusters_list/constants';
import { agent, kubernetesNamespace } from '../../../graphql/mock_data';
import { mockKasTunnelUrl, fluxResourceStatus, fluxKustomization } from '../../../mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('~/environments/environment_details/components/kubernetes/kubernetes_overview.vue', () => {
  let wrapper;

  const defaultProps = {
    environmentName: 'production',
    environmentId: '1',
    kubernetesNamespace,
  };

  const provide = {
    kasTunnelUrl: mockKasTunnelUrl,
    projectPath: 'path/to/project',
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

  let updateFluxResourceMutationMock;
  let fluxKustomizationQuery;
  let fluxHelmReleaseQuery;

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        fluxKustomization: fluxKustomizationQuery,
        fluxHelmRelease: fluxHelmReleaseQuery,
      },
      Mutation: {
        updateFluxResource: updateFluxResourceMutationMock,
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
      stubs: { GlSprintf },
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
    });
  };

  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesStatusBar = () => wrapper.findComponent(KubernetesStatusBar);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findWorkloadDetails = () => wrapper.findComponent(WorkloadDetails);
  const findDeletePodModal = () => wrapper.findComponent(DeletePodModal);
  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findConnectModal = () => wrapper.findComponent(ConnectToAgentModal);

  beforeEach(() => {
    updateFluxResourceMutationMock = jest.fn().mockResolvedValue({ errors: [] });
    fluxKustomizationQuery = jest.fn().mockReturnValue({});
    fluxHelmReleaseQuery = jest.fn().mockReturnValue({});
  });

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

    describe('actions menu', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('renders dropdown for the actions', () => {
        expect(findDisclosureDropdown().attributes('title')).toBe('Actions');
      });

      it('renders dropdown item for connecting to cluster action', () => {
        expect(findDisclosureDropdownItem().text()).toBe('Connect to agent');
      });

      it('binds dropdown item to the proper modal', () => {
        const binding = getBinding(findDisclosureDropdownItem().element, 'gl-modal-directive');

        expect(binding.value).toBe(CONNECT_MODAL_ID);
      });

      it('renders connect to agent modal', () => {
        expect(findConnectModal().props()).toEqual({
          agentId: 'gid://gitlab/ClusterAgent/1',
          projectPath: 'path/to/agent/project',
          isConfigured: true,
        });
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
          beforeEach(async () => {
            fluxKustomizationQuery = jest.fn().mockReturnValue(fluxKustomization);
            wrapper = createWrapper({
              apolloProvider: createApolloProvider(),
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

          beforeEach(async () => {
            fluxKustomizationQuery = jest.fn().mockRejectedValueOnce(error);
            fluxHelmReleaseQuery = jest.fn().mockRejectedValueOnce(error);
            wrapper = createWrapper({
              apolloProvider: createApolloProvider(),
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
          const eventHubSpy = jest.spyOn(eventHub, '$emit');

          expect(findDrawer().props('open')).toBe(true);

          await findDrawer().vm.$emit('close');
          expect(findDrawer().props('open')).toBe(false);
          expect(eventHubSpy).toHaveBeenCalledWith('closeDetailsDrawer');
        });

        it('is closed on remove-selection event', async () => {
          const eventHubSpy = jest.spyOn(eventHub, '$emit');

          expect(findDrawer().props('open')).toBe(true);

          await findKubernetesTabs().vm.$emit('remove-selection');
          expect(findDrawer().props('open')).toBe(false);
          expect(eventHubSpy).toHaveBeenCalledWith('closeDetailsDrawer');
        });
      });

      describe('when receives show-flux-resource-details event from the status bar', () => {
        beforeEach(async () => {
          fluxKustomizationQuery = jest.fn().mockReturnValue(fluxKustomization);
          wrapper = createWrapper({
            fluxResourcePath: kustomizationResourcePath,
            apolloProvider: createApolloProvider(),
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
            actions: [
              {
                name: 'flux-reconcile',
                text: 'Trigger reconciliation',
                icon: 'retry',
              },
            ],
          };
          expect(findWorkloadDetails().props('item')).toEqual(selectedItem);
        });

        it('renders a title with the selected item name', () => {
          expect(findDrawer().text()).toContain(fluxKustomization.metadata.name);
        });
      });
    });

    describe('flux reconciliation', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      describe('when successful', () => {
        beforeEach(async () => {
          fluxKustomizationQuery = jest.fn().mockReturnValue(fluxKustomization);
          updateFluxResourceMutationMock = jest.fn().mockResolvedValue({ errors: [] });
          wrapper = createWrapper({
            apolloProvider: createApolloProvider(),
            fluxResourcePath: kustomizationResourcePath,
          });
          await waitForPromises();

          findKubernetesStatusBar().vm.$emit('show-flux-resource-details', fluxKustomization);
          await nextTick();
          findWorkloadDetails().vm.$emit('flux-reconcile', fluxKustomization);
        });

        it('tracks `click_trigger_flux_reconciliation` event', () => {
          const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
          expect(trackEventSpy).toHaveBeenCalledWith(
            'click_trigger_flux_reconciliation',
            {},
            undefined,
          );
        });

        it('calls the mutation when receives `flux-reconcile` event', () => {
          const body = JSON.stringify([
            {
              op: 'replace',
              path: '/metadata/annotations/reconcile.fluxcd.io~1requestedAt',
              value: new Date(),
            },
          ]);

          expect(updateFluxResourceMutationMock).toHaveBeenCalledWith(
            {},
            {
              configuration,
              fluxResourcePath: kustomizationResourcePath,
              data: body,
            },
            expect.anything(),
            expect.anything(),
          );
        });

        it('closes the drawer when mutation is successful', async () => {
          expect(findDrawer().props('open')).toBe(true);
          await waitForPromises();
          expect(findDrawer().props('open')).toBe(false);
        });
      });

      describe('when errored', () => {
        const errorMessage = 'something went wrong';

        beforeEach(async () => {
          fluxKustomizationQuery = jest.fn().mockReturnValue(fluxKustomization);
          updateFluxResourceMutationMock = jest.fn().mockResolvedValue({ errors: [errorMessage] });
          wrapper = createWrapper({
            apolloProvider: createApolloProvider(),
            fluxResourcePath: kustomizationResourcePath,
          });
          await waitForPromises();

          findKubernetesStatusBar().vm.$emit('show-flux-resource-details', fluxKustomization);
          await nextTick();
          findWorkloadDetails().vm.$emit('flux-reconcile', fluxKustomization);
          await waitForPromises();
        });

        it('tracks `click_trigger_flux_reconciliation` event', () => {
          const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
          expect(trackEventSpy).toHaveBeenCalledWith(
            'click_trigger_flux_reconciliation',
            {},
            undefined,
          );
        });

        it('shows error alert if the pod was not deleted', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: `Error: ${errorMessage}`,
            variant: 'danger',
          });
        });
      });
    });

    describe('pod delete modal', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('is rendered with correct props', () => {
        const agentId = getIdFromGraphQLId(agent.id).toString();
        expect(findDeletePodModal().props()).toEqual({
          pod: {},
          configuration,
          agentId,
          environmentId: '1',
        });
      });

      it('provides correct pod when emitted from the tabs', async () => {
        const podToDelete = mockPodsTableItems[0];
        findKubernetesTabs().vm.$emit('delete-pod', podToDelete);
        await nextTick();

        expect(findDeletePodModal().props('pod')).toEqual(podToDelete);
      });

      it('provides correct pod when emitted from the details drawer', async () => {
        const podToDelete = mockPodsTableItems[1];
        findKubernetesTabs().vm.$emit('show-resource-details', mockPodsTableItems[1]);
        await nextTick();
        findWorkloadDetails().vm.$emit('delete-pod', podToDelete);
        await nextTick();

        expect(findDeletePodModal().props('pod')).toEqual(podToDelete);
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
