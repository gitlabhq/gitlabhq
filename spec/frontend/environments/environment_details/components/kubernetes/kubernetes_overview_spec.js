import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlEmptyState, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes/kubernetes_overview.vue';
import KubernetesStatusBar from '~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { agent, kubernetesNamespace, fluxResourcePathMock } from '../../../graphql/mock_data';
import { mockKasTunnelUrl } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_overview.vue', () => {
  Vue.use(VueApollo);

  let wrapper;

  const propsData = {
    environmentName: 'production',
    projectFullPath: 'gitlab-group/test-project',
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

  const createWrapper = (clusterAgent = agent) => {
    const defaultEnvironmentData = {
      data: {
        project: {
          id: '1',
          environment: {
            id: '1',
            clusterAgent,
            kubernetesNamespace,
            fluxResourcePath: fluxResourcePathMock,
          },
        },
      },
    };
    const mockApollo = createMockApollo([
      [environmentClusterAgentQuery, jest.fn().mockResolvedValue(defaultEnvironmentData)],
    ]);

    return shallowMount(KubernetesOverview, {
      apolloProvider: mockApollo,
      provide,
      propsData,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesStatusBar = () => wrapper.findComponent(KubernetesStatusBar);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('when fetching data', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders loading indicator', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it("doesn't render Kubernetes related components", () => {
      expect(findAgentInfo().exists()).toBe(false);
      expect(findKubernetesStatusBar().exists()).toBe(false);
      expect(findKubernetesTabs().exists()).toBe(false);
    });

    it("doesn't render empty state", () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when data is fetched', () => {
    it('hides loading indicator', async () => {
      wrapper = createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('and there is cluster agent data', () => {
      beforeEach(async () => {
        wrapper = createWrapper();
        await waitForPromises();
      });

      it('renders kubernetes agent info', () => {
        expect(findAgentInfo().props('clusterAgent')).toEqual(agent);
      });

      it('renders kubernetes tabs', () => {
        expect(findKubernetesTabs().props()).toEqual({
          namespace: kubernetesNamespace,
          configuration,
        });
      });

      it('renders kubernetes status bar', () => {
        expect(findKubernetesStatusBar().props()).toEqual({
          clusterHealthStatus: 'success',
          configuration,
          environmentName: propsData.environmentName,
          fluxResourcePath: fluxResourcePathMock,
        });
      });

      describe('Kubernetes health status', () => {
        beforeEach(async () => {
          wrapper = createWrapper();
          await waitForPromises();
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

      describe('on cluster error', () => {
        beforeEach(async () => {
          wrapper = createWrapper();
          await waitForPromises();
        });

        it('shows alert with the error message', async () => {
          const error = 'Error message from pods';

          findKubernetesTabs().vm.$emit('cluster-error', error);
          await nextTick();

          expect(findAlert().text()).toBe(error);
        });
      });
    });

    describe('and there is no cluster agent data', () => {
      beforeEach(async () => {
        wrapper = createWrapper(null);
        await waitForPromises();
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
});
