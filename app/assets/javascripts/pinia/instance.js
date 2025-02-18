import Vue from 'vue';
import { createPinia, PiniaVuePlugin } from 'pinia';
import { globalAccessorPlugin, syncWithVuex } from '~/pinia/plugins';

Vue.use(PiniaVuePlugin);

const pinia = createPinia();

pinia.use(syncWithVuex);
pinia.use(globalAccessorPlugin);

export { pinia };
