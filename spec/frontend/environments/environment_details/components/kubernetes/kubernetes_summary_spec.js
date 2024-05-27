import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import KubernetesSummary from '~/environments/environment_details/components/kubernetes/kubernetes_summary.vue';

describe('~/environments/environment_details/components/kubernetes/kubernetes_summary.vue', () => {
  let wrapper;

  const findTab = () => wrapper.findComponent(GlTab);

  const createWrapper = () => {
    wrapper = shallowMount(KubernetesSummary, {
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
  });
});
