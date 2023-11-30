import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlCollapse, GlButton, GlAlert } from '@gitlab/ui';
import KubernetesOverview from '~/environments/components/kubernetes_overview.vue';
import KubernetesAgentInfo from '~/environments/components/kubernetes_agent_info.vue';
import KubernetesPods from '~/environments/components/kubernetes_pods.vue';
import KubernetesTabs from '~/environments/components/kubernetes_tabs.vue';
import KubernetesStatusBar from '~/environments/components/kubernetes_status_bar.vue';
import {
  agent,
  kubernetesNamespace,
  resolvedEnvironment,
  fluxResourcePathMock,
} from './graphql/mock_data';
import { mockKasTunnelUrl } from './mock_data';

const propsData = {
  clusterAgent: agent,
  namespace: kubernetesNamespace,
  environmentName: resolvedEnvironment.name,
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

describe('~/environments/components/kubernetes_overview.vue', () => {
  let wrapper;

  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesPods = () => wrapper.findComponent(KubernetesPods);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
  const findKubernetesStatusBar = () => wrapper.findComponent(KubernetesStatusBar);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = () => {
    wrapper = shallowMount(KubernetesOverview, {
      propsData,
      provide,
    });
  };

  const toggleCollapse = async () => {
    findCollapseButton().vm.$emit('click');
    await nextTick();
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the kubernetes overview title', () => {
      expect(wrapper.text()).toBe(KubernetesOverview.i18n.sectionTitle);
    });
  });

  describe('collapse', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('is collapsed by default', () => {
      expect(findCollapse().props('visible')).toBeUndefined();
      expect(findCollapseButton().attributes('aria-label')).toBe(KubernetesOverview.i18n.expand);
      expect(findCollapseButton().props('icon')).toBe('chevron-right');
    });

    it("doesn't render components when the collapse is not visible", () => {
      expect(findAgentInfo().exists()).toBe(false);
      expect(findKubernetesPods().exists()).toBe(false);
    });

    it('opens on click', async () => {
      findCollapseButton().vm.$emit('click');
      await nextTick();

      expect(findCollapse().attributes('visible')).toBe('true');
      expect(findCollapseButton().attributes('aria-label')).toBe(KubernetesOverview.i18n.collapse);
      expect(findCollapseButton().props('icon')).toBe('chevron-down');
    });
  });

  describe('when section is expanded', () => {
    beforeEach(() => {
      createWrapper();
      toggleCollapse();
    });

    it('renders kubernetes agent info', () => {
      expect(findAgentInfo().props('clusterAgent')).toEqual(agent);
    });

    it('renders kubernetes pods', () => {
      expect(findKubernetesPods().props()).toEqual({
        namespace: kubernetesNamespace,
        configuration,
      });
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
        environmentName: resolvedEnvironment.name,
        fluxResourcePath: fluxResourcePathMock,
      });
    });
  });

  describe('Kubernetes health status', () => {
    beforeEach(() => {
      createWrapper();
      toggleCollapse();
    });

    it("doesn't set `clusterHealthStatus` when pods are still loading", async () => {
      findKubernetesPods().vm.$emit('loading', true);
      await nextTick();

      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('');
    });

    it("doesn't set `clusterHealthStatus` when workload types are still loading", async () => {
      findKubernetesTabs().vm.$emit('loading', true);
      await nextTick();

      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('');
    });

    it('sets `clusterHealthStatus` as error when pods emitted a failure', async () => {
      findKubernetesPods().vm.$emit('update-failed-state', { pods: true });
      await nextTick();

      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');
    });

    it('sets `clusterHealthStatus` as error when workload types emitted a failure', async () => {
      findKubernetesTabs().vm.$emit('update-failed-state', { summary: true });
      await nextTick();

      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');
    });

    it('sets `clusterHealthStatus` as success when data is loaded and no failures where emitted', () => {
      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('success');
    });

    it('sets `clusterHealthStatus` as success after state update if there are no failures', async () => {
      findKubernetesTabs().vm.$emit('update-failed-state', { summary: true });
      findKubernetesTabs().vm.$emit('update-failed-state', { pods: true });
      await nextTick();
      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');

      findKubernetesTabs().vm.$emit('update-failed-state', { summary: false });
      await nextTick();
      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('error');

      findKubernetesTabs().vm.$emit('update-failed-state', { pods: false });
      await nextTick();
      expect(findKubernetesStatusBar().props('clusterHealthStatus')).toBe('success');
    });
  });

  describe('on cluster error', () => {
    beforeEach(() => {
      createWrapper();
      toggleCollapse();
    });

    it('shows alert with the error message', async () => {
      const error = 'Error message from pods';

      findKubernetesPods().vm.$emit('cluster-error', error);
      await nextTick();

      expect(findAlert().text()).toBe(error);
    });
  });
});
