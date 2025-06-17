// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue from 'vue';
import { createPinia, defineStore, setActivePinia } from 'pinia';
import { syncWithVuex } from '~/pinia/plugins';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(Vuex);

describe('Pinia plugins', () => {
  describe('syncWithVuex', () => {
    let vuexStore;
    let usePiniaStore;
    let name;
    let namespaced;

    const getVuexName = (unprefixedName) =>
      namespaced ? `${name}/${unprefixedName}` : unprefixedName;
    const getVuexState = () => (name ? vuexStore.state[name] : vuexStore.state);

    const createState = () => ({
      primitive: 'foo',
      object: { key: 'bar' },
      nested: {
        object: {
          key: 'baz',
        },
      },
    });

    const createVuexStoreConfig = () => ({
      state() {
        return createState();
      },
      mutations: {
        setPrimitive(state, value) {
          state.primitive = value;
        },
        setObject(state, value) {
          state.object = value;
        },
        setDeepNested(state, value) {
          state.nested.object = value;
        },
      },
    });

    const createVuexStore = () => {
      vuexStore = new Vuex.Store(createVuexStoreConfig());
    };

    const createVuexStoreWithModule = () => {
      vuexStore = new Vuex.Store({
        modules: {
          [name]: {
            namespaced,
            ...createVuexStoreConfig(),
          },
        },
      });
    };

    const createSyncWithConfig = () => ({
      store: vuexStore,
      name,
      namespaced,
    });

    const createPiniaStore = (syncWith = createSyncWithConfig()) => {
      usePiniaStore = defineStore('exampleStore', {
        syncWith,
        state() {
          return createState();
        },
        actions: {
          setPrimitive(value) {
            this.primitive = value;
          },
          setObject(value) {
            this.object = value;
          },
          setDeepNested(value) {
            this.nested.object = value;
          },
        },
      });
    };

    describe.each([
      [
        'with a root level store',
        () => {
          createVuexStore();
          createPiniaStore();
          setActivePinia(createPinia().use(syncWithVuex));
        },
      ],
      [
        'with a namespaced store',
        () => {
          name = 'myStore';
          namespaced = true;
          createVuexStoreWithModule();
          createPiniaStore();
          setActivePinia(createPinia().use(syncWithVuex));
        },
      ],
      [
        'with a non namespaced named store',
        () => {
          name = 'myStore';
          namespaced = false;
          createVuexStoreWithModule();
          createPiniaStore();
          setActivePinia(createPinia().use(syncWithVuex));
        },
      ],
      [
        'with a non namespaced config override',
        () => {
          name = 'myStore';
          namespaced = false;
          createVuexStoreWithModule();
          createPiniaStore(undefined);
          setActivePinia(createPinia().use(syncWithVuex));
          usePiniaStore().syncWith(createSyncWithConfig());
        },
      ],
    ])('%s', (caseName, setupFn) => {
      beforeEach(() => {
        setupFn();
      });

      afterEach(() => {
        name = undefined;
        namespaced = undefined;
      });

      describe('primitives', () => {
        it('syncs Pinia with Vuex', () => {
          vuexStore.commit(getVuexName('setPrimitive'), 'newValue');
          expect(usePiniaStore().primitive).toBe('newValue');
        });

        it('syncs Vuex with Pinia', () => {
          usePiniaStore().setPrimitive('newValue');
          expect(getVuexState().primitive).toBe('newValue');
        });
      });

      describe('root objects', () => {
        it('syncs Pinia with Vuex', () => {
          const obj = { foo: 1 };
          vuexStore.commit(getVuexName('setObject'), obj);
          expect(usePiniaStore().object).toStrictEqual(obj);
        });

        it('syncs Vuex with Pinia after Pinia is initialized', () => {
          usePiniaStore();
          const obj = { foo: 1 };
          vuexStore.commit(getVuexName('setObject'), obj);
          expect(usePiniaStore().object).toStrictEqual(obj);
        });

        it('syncs Vuex with Pinia', () => {
          const obj = { foo: 1 };
          usePiniaStore().setObject(obj);
          expect(getVuexState().object).toStrictEqual(obj);
        });
      });

      describe('nested objects', () => {
        it('syncs Pinia with Vuex', async () => {
          const obj = { foo: 1 };
          vuexStore.commit(getVuexName('setDeepNested'), obj);
          await waitForPromises();
          expect(usePiniaStore().nested.object).toStrictEqual(obj);
        });

        it('syncs Pinia with Vuex after Pinia is initialized', async () => {
          usePiniaStore();
          const obj = { foo: 1 };
          vuexStore.commit(getVuexName('setDeepNested'), obj);
          await waitForPromises();
          expect(usePiniaStore().nested.object).toStrictEqual(obj);
        });

        it('syncs Vuex with Pinia', () => {
          const obj = { foo: 1 };
          usePiniaStore().setDeepNested(obj);
          expect(getVuexState().nested.object).toStrictEqual(obj);
        });
      });
    });
  });
});
