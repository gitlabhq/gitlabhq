import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';
import { fluxKustomization } from '../../../mock_data';

describe('~/environments/environment_details/components/kubernetes/kubernetes_summary.vue', () => {
  let wrapper;

  const findTab = () => wrapper.findComponent(GlTab);

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
      expect(findTab().text()).toContain('Tree view');
    });

    it('renders kustomization resource data', () => {
      expect(findTab().text()).toContain('Kustomization: my-kustomization');
    });
  });
});
