import Vue from 'vue';
import { createPinia, PiniaVuePlugin } from 'pinia';
import { syncWithVuex } from '~/pinia/plugins';

Vue.use(PiniaVuePlugin);

const pinia = createPinia();

pinia.use(syncWithVuex);

export { pinia };
