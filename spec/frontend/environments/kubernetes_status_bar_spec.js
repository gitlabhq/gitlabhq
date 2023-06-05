import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlBadge } from '@gitlab/ui';
import KubernetesStatusBar from '~/environments/components/kubernetes_status_bar.vue';
import {
  CLUSTER_STATUS_HEALTHY_TEXT,
  CLUSTER_STATUS_UNHEALTHY_TEXT,
} from '~/environments/constants';

describe('~/environments/components/kubernetes_status_bar.vue', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHealthBadge = () => wrapper.findComponent(GlBadge);

  const createWrapper = ({ clusterHealthStatus = '' } = {}) => {
    wrapper = shallowMount(KubernetesStatusBar, {
      propsData: { clusterHealthStatus },
    });
  };

  describe('health badge', () => {
    it('shows loading icon when cluster health is not present', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it.each([
      ['success', 'success', CLUSTER_STATUS_HEALTHY_TEXT],
      ['error', 'danger', CLUSTER_STATUS_UNHEALTHY_TEXT],
    ])(
      'when clusterHealthStatus is %s shows health badge with variant %s and text %s',
      (status, variant, text) => {
        createWrapper({ clusterHealthStatus: status });

        expect(findLoadingIcon().exists()).toBe(false);
        expect(findHealthBadge().props('variant')).toBe(variant);
        expect(findHealthBadge().text()).toBe(text);
      },
    );
  });
});
