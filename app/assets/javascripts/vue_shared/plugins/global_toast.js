import { GlToast } from '@gitlab/ui';
import Vue from 'vue';

Vue.use(GlToast);
const instance = new Vue();

export default function showGlobalToast(...args) {
  return instance.$toast.show(...args);
}
