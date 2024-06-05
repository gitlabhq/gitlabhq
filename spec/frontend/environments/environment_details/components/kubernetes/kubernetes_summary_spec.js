import { GlTab } from '@gitlab/ui';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';
import KubernetesTreeItem from '~/environments/environment_details/components/kubernetes/kubernetes_tree_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { fluxKustomization } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_summary.vue', () => {
  let wrapper;

  const findTab = () => wrapper.findComponent(GlTab);
  const findTreeItem = () => wrapper.findComponent(KubernetesTreeItem);
  const findRelatedDeployments = () => wrapper.findByTestId('related-deployments');
  const findAllDeploymentItems = () =>
    findRelatedDeployments().findAllComponents(KubernetesTreeItem);
  const findDeploymentItem = (at) => findAllDeploymentItems().at(at);

  const createWrapper = () => {
    wrapper = shallowMountExtended(KubernetesSummary, {
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

    describe('related deployments', () => {
      it('renders a tree item for each related deployment', () => {
        expect(findAllDeploymentItems()).toHaveLength(2);
      });

      it.each([
        ['notification-controller', 0],
        ['source-controller', 1],
      ])('renders a tree item with name %s at %d', (name, index) => {
        expect(findDeploymentItem(index).props()).toEqual({ kind: 'Deployment', status: '', name });
      });
    });
  });
});
