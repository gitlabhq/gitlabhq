import { createApp } from 'vue-demi';
import { createPinia } from 'pinia';
import waitForPromises from 'helpers/wait_for_promises';

// Under Vue 3, Pinia holds back plugins registered with `use()` until it is installed into an app,
// so a store-only spec would silently never get them. Install into a throwaway app to flush them.
export const createTestPinia = () => {
  const pinia = createPinia();
  createApp({}).use(pinia);
  return pinia;
};

// Use this to migrate from Vuex to Pinia
// DO NOT use for proper Pinia testing, instead use regular Jest API: mocks, expects, etc.
export const createTestPiniaAction =
  (store) =>
  // eslint-disable-next-line max-params
  async (action, payload, state, expectedMutations = [], expectedActions = []) => {
    const actionCalls = [];
    store.$onAction((actionCall) => {
      actionCalls.push(actionCall);
    });
    store.$patch(state);

    const result = await action(payload);

    actionCalls.shift();

    await waitForPromises();

    const expected = [...expectedMutations, ...expectedActions];
    if (expected.length) {
      const calls = new Map();
      expected.forEach((expectedAction) => {
        const callCount = calls.get(expectedAction.type) || 0;
        const currentCallIndex = callCount + 1;
        if (expectedAction.payload) {
          expect(expectedAction.type).toHaveBeenNthCalledWith(
            currentCallIndex,
            expectedAction.payload,
          );
        } else {
          expect(expectedAction.type).toHaveBeenCalled();
        }
        calls.set(expectedAction.type, currentCallIndex);
      });
    } else {
      // eslint-disable-next-line jest/no-standalone-expect
      expect(actionCalls).toHaveLength(0);
    }

    return result;
  };

// Use this to migrate from Vuex to Pinia
// DO NOT use this in proper Pinia tests, mutate your state instead
export const createCustomGetters =
  (getters) =>
  ({ store, options }) => {
    if (!options.getters) return;
    Object.keys(options.getters).forEach((getter) => {
      Object.defineProperty(store, getter, {
        get: () => getters()[store.$id][getter] || options.getters[getter].call(store),
      });
    });
  };
