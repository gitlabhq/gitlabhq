import { GlToastMixin } from '@gitlab/ui';
import Vue from 'vue';
import { pageSingleton } from '~/lib/utils/page_singleton';

const getInstance = () =>
  pageSingleton(
    'global_toast',
    () => new Vue({ name: 'GlobalToastRoot', mixins: [GlToastMixin], render: () => null }),
  );

export default function showGlobalToast(...args) {
  return getInstance().$toast.show(...args);
}
