import VueRouter from 'vue-router';
import waitForPromises from 'helpers/wait_for_promises';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import { createStore } from '~/ide/stores';
import { syncRouterAndStore } from '~/ide/sync_router_and_store';

const TEST_ROUTE = '/test/lorem/ipsum';

const skipReason = new SkipReason({
  name: '~/ide/sync_router_and_store',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  let unsync;
  let router;
  let store;
  let onRouterChange;

  const createSync = () => {
    unsync = syncRouterAndStore(router, store);
  };

  const getRouterCurrentPath = () => router.currentRoute.fullPath;
  const getStoreCurrentPath = () => store.state.router.fullPath;
  const updateRouter = async (path) => {
    if (getRouterCurrentPath() === path) {
      return;
    }

    router.push(path);
    await waitForPromises();
  };
  const updateStore = (path) => {
    store.dispatch('router/push', path);
    return waitForPromises();
  };

  beforeEach(() => {
    router = new VueRouter();
    store = createStore();
    jest.spyOn(store, 'dispatch');

    onRouterChange = jest.fn();
    router.beforeEach((to, from, next) => {
      onRouterChange(to, from);
      next();
    });
  });

  afterEach(() => {
    unsync();
    unsync = null;
  });

  it('keeps store and router in sync', async () => {
    createSync();

    await updateRouter('/test/test');
    await updateRouter('/test/test');
    await updateStore('123/abc');
    await updateRouter('def');

    // Even though we pused relative paths, the store and router kept track of the resulting fullPath
    expect(getRouterCurrentPath()).toBe('/test/123/def');
    expect(getStoreCurrentPath()).toBe('/test/123/def');
  });

  describe('default', () => {
    beforeEach(() => {
      createSync();
    });

    it('store is default', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
      expect(getStoreCurrentPath()).toBe('');
    });

    it('router is default', () => {
      expect(onRouterChange).not.toHaveBeenCalled();
      expect(getRouterCurrentPath()).toBe('/');
    });

    describe('when store changes', () => {
      beforeEach(() => {
        updateStore(TEST_ROUTE);
      });

      it('store is updated', () => {
        // let's make sure the action isn't dispatched more than necessary
        expect(store.dispatch).toHaveBeenCalledTimes(1);
        expect(getStoreCurrentPath()).toBe(TEST_ROUTE);
      });

      it('router is updated', () => {
        expect(onRouterChange).toHaveBeenCalledTimes(1);
        expect(getRouterCurrentPath()).toBe(TEST_ROUTE);
      });

      describe('when store changes again to the same thing', () => {
        beforeEach(() => {
          onRouterChange.mockClear();
          updateStore(TEST_ROUTE);
        });

        it('doesnt change router again', () => {
          expect(onRouterChange).not.toHaveBeenCalled();
        });
      });
    });

    describe('when router changes', () => {
      beforeEach(() => {
        updateRouter(TEST_ROUTE);
      });

      it('store is updated', () => {
        expect(store.dispatch).toHaveBeenCalledTimes(1);
        expect(getStoreCurrentPath()).toBe(TEST_ROUTE);
      });

      it('router is updated', () => {
        // let's make sure the router change isn't triggered more than necessary
        expect(onRouterChange).toHaveBeenCalledTimes(1);
        expect(getRouterCurrentPath()).toBe(TEST_ROUTE);
      });

      describe('when router changes again to the same thing', () => {
        beforeEach(() => {
          store.dispatch.mockClear();
          updateRouter(TEST_ROUTE);
        });

        it('doesnt change store again', () => {
          expect(store.dispatch).not.toHaveBeenCalled();
        });
      });
    });

    describe('when disposed', () => {
      beforeEach(() => {
        unsync();
      });

      it('a store change does not trigger a router change', () => {
        updateStore(TEST_ROUTE);

        expect(getRouterCurrentPath()).toBe('/');
        expect(onRouterChange).not.toHaveBeenCalled();
      });

      it('a router change does not trigger a store change', () => {
        updateRouter(TEST_ROUTE);

        expect(getStoreCurrentPath()).toBe('');
        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });
  });
});
