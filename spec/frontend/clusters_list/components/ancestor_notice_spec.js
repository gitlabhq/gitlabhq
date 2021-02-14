import { GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AncestorNotice from '~/clusters_list/components/ancestor_notice.vue';
import ClusterStore from '~/clusters_list/store';

describe('ClustersAncestorNotice', () => {
  let store;
  let wrapper;

  const createWrapper = () => {
    store = ClusterStore({ ancestorHelperPath: '/some/ancestor/path' });
    wrapper = shallowMount(AncestorNotice, { store, stubs: { GlSprintf, GlAlert } });
    return wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    return createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when cluster does not have ancestors', () => {
    beforeEach(() => {
      store.state.hasAncestorClusters = false;
      return wrapper.vm.$nextTick();
    });

    it('displays no notice', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('when cluster has ancestors', () => {
    beforeEach(() => {
      store.state.hasAncestorClusters = true;
      return wrapper.vm.$nextTick();
    });

    it('displays notice text', () => {
      expect(wrapper.text()).toContain(
        'Clusters are utilized by selecting the nearest ancestor with a matching environment scope. For example, project clusters will override group clusters.',
      );
    });

    it('displays link', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
    });
  });
});
