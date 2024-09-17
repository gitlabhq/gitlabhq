import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';
import KubernetesTabs from '~/environments/environment_details/components/kubernetes/kubernetes_tabs.vue';
import KubernetesPods from '~/environments/environment_details/components/kubernetes/kubernetes_pods.vue';
import KubernetesServices from '~/environments/environment_details/components/kubernetes/kubernetes_services.vue';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';
import { k8sResourceType } from '~/environments/graphql/resolvers/kubernetes/constants';
import { mockKasTunnelUrl, fluxKustomization } from 'jest/environments/mock_data';
import { mockPodsTableItems } from 'jest/kubernetes_dashboard/graphql/mock_data';

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
  const findKubernetesSummary = () => wrapper.findComponent(KubernetesSummary);

  const createWrapper = ({
    activeTab = k8sResourceType.k8sPods,
    k8sTreeViewEnabled = false,
  } = {}) => {
    wrapper = shallowMount(KubernetesTabs, {
      provide: {
        glFeatures: { k8sTreeView: k8sTreeViewEnabled },
      },
      propsData: { configuration, namespace, fluxKustomization, value: activeTab },
    });
  };

  describe('mounted', () => {
    describe('when `k8sTreeView feature flag is enabled', () => {
      beforeEach(() => {
        createWrapper({ k8sTreeViewEnabled: true });
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

      it('renders summary tab', () => {
        expect(findKubernetesSummary().props()).toEqual({
          namespace,
          configuration,
          fluxKustomization,
        });
      });
    });

    it('renders summary tab if the feature flag is disabled', () => {
      createWrapper();

      expect(findKubernetesSummary().exists()).toBe(false);
    });
  });

  describe('active tab tracking', () => {
    describe('when `k8sTreeView feature flag is enabled', () => {
      const summaryTab = 'summary';
      it.each([
        [k8sResourceType.k8sPods, 1, 2, k8sResourceType.k8sServices],
        [k8sResourceType.k8sServices, 2, 1, k8sResourceType.k8sPods],
        [summaryTab, 0, 2, k8sResourceType.k8sServices],
      ])(
        'when activeTab is %s, it activates the right tab and emit the correct tab name when switching',
        // eslint-disable-next-line max-params
        async (activeTab, tabIndex, newTabIndex, newActiveTab) => {
          createWrapper({ k8sTreeViewEnabled: true, activeTab });
          const tabsComponent = findTabs();
          expect(tabsComponent.props('value')).toBe(tabIndex);

          tabsComponent.vm.$emit('input', newTabIndex);
          await nextTick();
          expect(wrapper.emitted('input')).toEqual([[newActiveTab]]);
        },
      );
    });
    describe('when `k8sTreeView feature flag is disabled', () => {
      it.each([
        [k8sResourceType.k8sPods, 0, 1, k8sResourceType.k8sServices],
        [k8sResourceType.k8sServices, 1, 0, k8sResourceType.k8sPods],
      ])(
        'when activeTab is %s, it activates the right tab and emit the correct tab name when switching',
        // eslint-disable-next-line max-params
        async (activeTab, tabIndex, newTabIndex, newActiveTab) => {
          createWrapper({ activeTab });
          await nextTick();
          const tabsComponent = findTabs();
          await nextTick();
          expect(tabsComponent.props('value')).toBe(tabIndex);

          tabsComponent.vm.$emit('input', newTabIndex);
          await nextTick();
          expect(wrapper.emitted('input')).toEqual([[newActiveTab]]);
        },
      );
    });
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

    it('emits select-item event when gets it from the component', () => {
      findKubernetesPods().vm.$emit('select-item', mockPodsTableItems[0]);

      expect(wrapper.emitted('select-item')).toEqual([[mockPodsTableItems[0]]]);
    });

    it('emits a cluster error event when gets it from the component', () => {
      const errorMessage = 'Error from the cluster_client API';
      findKubernetesPods().vm.$emit('cluster-error', errorMessage);
      expect(wrapper.emitted('cluster-error')).toEqual([[errorMessage]]);
    });

    it('emits delete pod event when gets it from the component', () => {
      expect(wrapper.emitted('delete-pod')).toBeUndefined();

      findKubernetesPods().vm.$emit('delete-pod', mockPodsTableItems[0]);
      expect(wrapper.emitted('delete-pod')).toEqual([[mockPodsTableItems[0]]]);
    });
  });
});
