import Vue from 'vue';
import { GlToast } from '@gitlab/ui';

Vue.use(GlToast);
const instance = new Vue();

export default function showGlobalToast(...args) {
  return instance.$toast.show(...args);
}
