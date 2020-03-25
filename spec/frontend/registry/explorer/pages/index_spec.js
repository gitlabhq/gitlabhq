import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import component from '~/registry/explorer/pages/index.vue';
import store from '~/registry/explorer/stores/';

describe('List Page', () => {
  let wrapper;
  let dispatchSpy;

  const findRouterView = () => wrapper.find({ ref: 'router-view' });
  const findAlert = () => wrapper.find(GlAlert);
  const findLink = () => wrapper.find(GlLink);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
      store,
      stubs: {
        RouterView: true,
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    dispatchSpy = jest.spyOn(store, 'dispatch');
    mountComponent();
  });

  it('has a router view', () => {
    expect(findRouterView().exists()).toBe(true);
  });

  describe('garbageCollectionTip alert', () => {
    beforeEach(() => {
      store.dispatch('setInitialState', { isAdmin: true, garbageCollectionHelpPagePath: 'foo' });
      store.dispatch('setShowGarbageCollectionTip', true);
    });

    afterEach(() => {
      store.dispatch('setInitialState', {});
      store.dispatch('setShowGarbageCollectionTip', false);
    });

    it('is visible when the user is an admin and the user performed a delete action', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('on dismiss disappears ', () => {
      findAlert().vm.$emit('dismiss');
      expect(dispatchSpy).toHaveBeenCalledWith('setShowGarbageCollectionTip', false);
      return wrapper.vm.$nextTick().then(() => {
        expect(findAlert().exists()).toBe(false);
      });
    });

    it('contains a link to the docs', () => {
      const link = findLink();
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(store.state.config.garbageCollectionHelpPagePath);
    });
  });
});
