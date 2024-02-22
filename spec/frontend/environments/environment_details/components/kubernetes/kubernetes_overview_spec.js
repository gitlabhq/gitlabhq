import { nextTick } from 'vue';
import { GlEmptyState, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import KubernetesOverview from '~/environments/environment_details/components/kubernetes/kubernetes_overview.vue';
import KubernetesStatusBar from '~/environments/environment_details/components/kubernetes/kubernetes_status_bar.vue';
import KubernetesAgentInfo from '~/environments/environment_details/components/kubernetes/kubernetes_agent_info.vue';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import { agent, kubernetesNamespace, fluxResourcePathMock } from '../../../graphql/mock_data';
import { mockKasTunnelUrl } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_overview.vue', () => {
  let wrapper;

  const defaultProps = {
    environmentName: 'production',
    kubernetesNamespace,
    fluxResourcePath: fluxResourcePathMock,
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
    return shallowMount(KubernetesOverview, {
      provide,
      propsData: {
        ...defaultProps,
        clusterAgent,
      },
    });
  };

  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesStatusBar = () => wrapper.findComponent(KubernetesStatusBar);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('when the agent data is present', () => {
    beforeEach(() => {
      wrapper = createWrapper();
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
        environmentName: defaultProps.environmentName,
        fluxResourcePath: fluxResourcePathMock,
      });
    });

    describe('Kubernetes health status', () => {
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
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows alert with the error message', async () => {
        const error = 'Error message from pods';

        findKubernetesTabs().vm.$emit('cluster-error', error);
        await nextTick();

        expect(findAlert().text()).toBe(error);
      });
    });
  });

  describe('when there is no cluster agent data', () => {
    beforeEach(() => {
      wrapper = createWrapper(null);
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
