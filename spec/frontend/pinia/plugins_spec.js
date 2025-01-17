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

    const createState = () => ({
      primitive: 'foo',
      object: { key: 'bar' },
      nested: {
        object: {
          key: 'baz',
        },
      },
    });

    const createVuexStore = () => {
      vuexStore = new Vuex.Store({
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
    };

    const createPiniaStore = () => {
      usePiniaStore = defineStore('exampleStore', {
        syncWith: vuexStore,
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

    beforeEach(() => {
      createVuexStore();
      createPiniaStore();
      setActivePinia(createPinia().use(syncWithVuex));
    });

    describe('primitives', () => {
      it('syncs Pinia with Vuex', () => {
        vuexStore.commit('setPrimitive', 'newValue');
        expect(usePiniaStore().primitive).toBe('newValue');
      });

      it('syncs Vuex with Pinia', () => {
        usePiniaStore().setPrimitive('newValue');
        expect(vuexStore.state.primitive).toBe('newValue');
      });
    });

    describe('root objects', () => {
      it('syncs Pinia with Vuex', () => {
        const obj = { foo: 1 };
        vuexStore.commit('setObject', obj);
        expect(usePiniaStore().object).toStrictEqual(obj);
      });

      it('syncs Vuex with Pinia after Pinia is initialized', () => {
        usePiniaStore();
        const obj = { foo: 1 };
        vuexStore.commit('setObject', obj);
        expect(usePiniaStore().object).toStrictEqual(obj);
      });

      it('syncs Vuex with Pinia', () => {
        const obj = { foo: 1 };
        usePiniaStore().setObject(obj);
        expect(vuexStore.state.object).toStrictEqual(obj);
      });
    });

    describe('nested objects', () => {
      it('syncs Pinia with Vuex', async () => {
        const obj = { foo: 1 };
        vuexStore.commit('setDeepNested', obj);
        await waitForPromises();
        expect(usePiniaStore().nested.object).toStrictEqual(obj);
      });

      it('syncs Pinia with Vuex after Pinia is initialized', async () => {
        usePiniaStore();
        const obj = { foo: 1 };
        vuexStore.commit('setDeepNested', obj);
        await waitForPromises();
        expect(usePiniaStore().nested.object).toStrictEqual(obj);
      });

      it('syncs Vuex with Pinia', () => {
        const obj = { foo: 1 };
        usePiniaStore().setDeepNested(obj);
        expect(vuexStore.state.nested.object).toStrictEqual(obj);
      });
    });
  });
});
