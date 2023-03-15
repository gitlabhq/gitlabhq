import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlCollapse, GlButton } from '@gitlab/ui';
import KubernetesOverview from '~/environments/components/kubernetes_overview.vue';
import KubernetesAgentInfo from '~/environments/components/kubernetes_agent_info.vue';

const agent = {
  project: 'agent-project',
  id: '1',
  name: 'agent-name',
};

const propsData = {
  agentId: agent.id,
  agentName: agent.name,
  agentProjectPath: agent.project,
};

describe('~/environments/components/kubernetes_overview.vue', () => {
  let wrapper;

  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findAgentInfo = () => wrapper.findComponent(KubernetesAgentInfo);

  const createWrapper = () => {
    wrapper = shallowMount(KubernetesOverview, {
      propsData,
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
    it('renders kubernetes agent info', async () => {
      createWrapper();
      await toggleCollapse();

      expect(findAgentInfo().props()).toEqual({
        agentName: agent.name,
        agentId: agent.id,
        agentProjectPath: agent.project,
      });
    });
  });
});
