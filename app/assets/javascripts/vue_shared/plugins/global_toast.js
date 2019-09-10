import Vue from 'vue';
import { GlToast } from '@gitlab/ui';

Vue.use(GlToast);

export default function showGlobalToast(...args) {
  return Vue.toasted.show(...args);
}
