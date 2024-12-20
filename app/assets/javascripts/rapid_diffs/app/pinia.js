import Vue from 'vue';
import { createPinia, PiniaVuePlugin } from 'pinia';

Vue.use(PiniaVuePlugin);
export const pinia = createPinia();
