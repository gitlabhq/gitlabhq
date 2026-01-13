import Vue from 'vue';
import { createPinia, PiniaVuePlugin, setActivePinia } from 'pinia';
import { globalAccessorPlugin, syncWithVuex } from '~/pinia/plugins';

Vue.use(PiniaVuePlugin);

const pinia = createPinia();

setActivePinia(pinia);

// FIX: Set _a to truthy value so plugins go to _p directly
// instead of being deferred (which never get applied in compat mode)
// eslint-disable-next-line no-underscore-dangle
pinia._a = pinia._a || {};

pinia.use(syncWithVuex);
pinia.use(globalAccessorPlugin);

export { pinia };
