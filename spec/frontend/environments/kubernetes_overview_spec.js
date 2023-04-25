import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlCollapse, GlButton, GlAlert } from '@gitlab/ui';
import KubernetesOverview from '~/environments/components/kubernetes_overview.vue';
import KubernetesAgentInfo from '~/environments/components/kubernetes_agent_info.vue';
import KubernetesPods from '~/environments/components/kubernetes_pods.vue';
import KubernetesTabs from '~/environments/components/kubernetes_tabs.vue';
import { agent } from './graphql/mock_data';
import { mockKasTunnelUrl } from './mock_data';

const propsData = {
  agentId: agent.id,
  agentName: agent.name,
  agentProjectPath: agent.project,
  namespace: agent.kubernetesNamespace,
};

const provide = {
  kasTunnelUrl: mockKasTunnelUrl,
};

const configuration = {
  basePath: provide.kasTunnelUrl.replace(/\/$/, ''),
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
  },
};

describe('~/environments/components/kubernetes_overview.vue', () => {
  let wrapper;

  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);
  const findKubernetesPods = () => wrapper.findComponent(KubernetesPods);
  const findKubernetesTabs = () => wrapper.findComponent(KubernetesTabs);
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
      expect(findAgentInfo().props()).toEqual({
        agentName: agent.name,
        agentId: agent.id,
        agentProjectPath: agent.project,
      });
    });

    it('renders kubernetes pods', () => {
      expect(findKubernetesPods().props()).toEqual({
        namespace: agent.kubernetesNamespace,
        configuration,
      });
    });

    it('renders kubernetes tabs', () => {
      expect(findKubernetesTabs().props()).toEqual({
        configuration,
      });
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
