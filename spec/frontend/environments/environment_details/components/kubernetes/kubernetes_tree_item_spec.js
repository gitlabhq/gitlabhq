import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import KubernetesTreeItem from '~/environments/environment_details/components/kubernetes/kubernetes_tree_item.vue';
import { TREE_ITEM_KIND_ICONS, TREE_ITEM_STATUS_ICONS } from '~/environments/constants';

describe('~/environments/environment_details/components/kubernetes/kubernetes_tree_item.vue', () => {
  let wrapper;

  const kind = 'Kustomization';
  const name = 'my-kustomization';
  const statusReconciled = 'reconciled';

  const findKindIcon = () => wrapper.findByTestId('resource-kind-icon');
  const findStatusIcon = () => wrapper.findByTestId('resource-status-icon');

  const createWrapper = ({ status = statusReconciled } = {}) => {
    wrapper = shallowMountExtended(KubernetesTreeItem, {
      propsData: {
        kind,
        name,
        status,
      },
    });
  };

  describe('mounted', () => {
    it('renders correct kind icon', () => {
      createWrapper();

      expect(findKindIcon().props('name')).toBe(TREE_ITEM_KIND_ICONS[kind]);
    });

    it('renders correct kind and name', () => {
      createWrapper();

      expect(wrapper.text()).toBe(`${kind}: ${name}`);
    });

    it('renders correct status icon when the status is provided', () => {
      createWrapper();

      const iconData = TREE_ITEM_STATUS_ICONS.reconciled;

      expect(findStatusIcon().props('name')).toBe(iconData.icon);
      expect(findStatusIcon().props('variant')).toContain(iconData.variant);
      expect(findStatusIcon().attributes('title')).toBe(statusReconciled);
    });

    it("doesn't render status icon when the status is not provided", () => {
      createWrapper({ status: '' });

      expect(findStatusIcon().exists()).toBe(false);
    });
  });
});
