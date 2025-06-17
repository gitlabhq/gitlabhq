import Vue from 'vue';
import { createPinia, PiniaVuePlugin, setActivePinia } from 'pinia';
import { globalAccessorPlugin, syncWithVuex } from '~/pinia/plugins';

Vue.use(PiniaVuePlugin);

const pinia = createPinia();

setActivePinia(pinia);

pinia.use(syncWithVuex);
pinia.use(globalAccessorPlugin);

export { pinia };
