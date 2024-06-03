import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';
import KubernetesTreeItem from '~/environments/environment_details/components/kubernetes/kubernetes_tree_item.vue';
import { fluxKustomization } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_summary.vue', () => {
  let wrapper;

  const findTab = () => wrapper.findComponent(GlTab);
  const findTreeItem = () => wrapper.findComponent(KubernetesTreeItem);

  const createWrapper = () => {
    wrapper = shallowMount(KubernetesSummary, {
      propsData: {
        fluxKustomization,
      },
      stubs: { GlTab },
    });
  };

  describe('mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders summary tab', () => {
      expect(findTab().attributes('title')).toBe('Summary');
    });

    it('renders tree view title', () => {
      expect(findTab().text()).toBe('Tree view');
    });

    it('renders tree item with kustomization resource data', () => {
      expect(findTreeItem().props()).toEqual({
        kind: 'Kustomization',
        name: 'my-kustomization',
        status: 'reconciled',
      });
    });
  });
});
