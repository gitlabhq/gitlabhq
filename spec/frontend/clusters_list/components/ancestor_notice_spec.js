import { GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AncestorNotice from '~/clusters_list/components/ancestor_notice.vue';
import ClusterStore from '~/clusters_list/store';

describe('ClustersAncestorNotice', () => {
  let store;
  let wrapper;

  const createWrapper = async () => {
    store = ClusterStore({ ancestorHelperPath: '/some/ancestor/path' });
    wrapper = shallowMount(AncestorNotice, { store, stubs: { GlSprintf, GlAlert } });
    await nextTick();
  };

  beforeEach(() => {
    return createWrapper();
  });

  describe('when cluster does not have ancestors', () => {
    beforeEach(async () => {
      store.state.hasAncestorClusters = false;
      await nextTick();
    });

    it('displays no notice', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe('when cluster has ancestors', () => {
    beforeEach(async () => {
      store.state.hasAncestorClusters = true;
      await nextTick();
    });

    it('displays notice text', () => {
      expect(wrapper.text()).toContain(
        'Clusters are utilized by selecting the nearest ancestor with a matching environment scope. For example, project clusters will override group clusters.',
      );
    });

    it('displays link', () => {
      expect(wrapper.findComponent(GlLink).exists()).toBe(true);
    });
  });
});
