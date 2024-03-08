import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import KubernetesPods from '~/environments/environment_details/components/kubernetes/kubernetes_pods.vue';
import KubernetesServices from '~/environments/environment_details/components/kubernetes/kubernetes_services.vue';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import { mockKasTunnelUrl } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue', () => {
  let wrapper;

  const namespace = 'my-kubernetes-namespace';
  const configuration = {
    basePath: mockKasTunnelUrl,
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findKubernetesPods = () => wrapper.findComponent(KubernetesPods);
  const findKubernetesServices = () => wrapper.findComponent(KubernetesServices);

  const createWrapper = (activeTab = k8sResourceType.k8sPods) => {
    wrapper = shallowMount(KubernetesTabs, {
      propsData: { configuration, namespace, value: activeTab },
    });
  };

  describe('mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows tabs', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders pods tab', () => {
      expect(findKubernetesPods().props()).toEqual({ namespace, configuration });
    });

    it('renders services tab', () => {
      expect(findKubernetesServices().props()).toEqual({ namespace, configuration });
    });
  });

  describe('active tab tracking', () => {
    it.each([
      [k8sResourceType.k8sPods, 0, 1, k8sResourceType.k8sServices],
      [k8sResourceType.k8sServices, 1, 0, k8sResourceType.k8sPods],
    ])(
      'when activeTab is %s, it activates the right tab and emit the correct tab name when switching',
      async (activeTab, tabIndex, newTabIndex, newActiveTab) => {
        createWrapper(activeTab);
        const tabsComponent = findTabs();
        expect(tabsComponent.props('value')).toBe(tabIndex);

        tabsComponent.vm.$emit('input', newTabIndex);
        await nextTick();
        expect(wrapper.emitted('input')).toEqual([[newActiveTab]]);
      },
    );
  });

  describe('services tab', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('emits a cluster error event when gets it from the component', () => {
      const errorMessage = 'Error from the cluster_client API';
      findKubernetesServices().vm.$emit('cluster-error', errorMessage);
      expect(wrapper.emitted('cluster-error')).toEqual([[errorMessage]]);
    });
  });

  describe('pods tab', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('emits loading event when gets it from the component', () => {
      findKubernetesPods().vm.$emit('loading', true);
      expect(wrapper.emitted('loading')[0]).toEqual([true]);

      findKubernetesPods().vm.$emit('loading', false);
      expect(wrapper.emitted('loading')[1]).toEqual([false]);
    });

    it('emits a state update event when gets it from the component', () => {
      const eventData = { pods: true };
      findKubernetesPods().vm.$emit('update-failed-state', eventData);
      expect(wrapper.emitted('update-failed-state')).toEqual([[eventData]]);
    });

    it('emits a cluster error event when gets it from the component', () => {
      const errorMessage = 'Error from the cluster_client API';
      findKubernetesPods().vm.$emit('cluster-error', errorMessage);
      expect(wrapper.emitted('cluster-error')).toEqual([[errorMessage]]);
    });
  });
});
