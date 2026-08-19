import { GlToastMixin } from '@gitlab/ui';
import Vue from 'vue';

const instance = new Vue({ name: 'GlobalToastRoot', mixins: [GlToastMixin], render: () => null });

export default function showGlobalToast(...args) {
  return instance.$toast.show(...args);
}
