import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import ReleaseIndexApp from './components/app_index.vue';

export default () => {
  const el = document.getElementById('js-releases-page');

  Vue.use(VueApollo);
  Vue.use(GlToast);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        // This page attempts to decrease the perceived loading time
        // by sending two requests: one request for the first item only (which
        // completes relatively quickly), and one for all the items (which is slower).
        // By default, Apollo Client batches these requests together, which defeats
        // the purpose of making separate requests. So we explicitly
        // disable batching on this page.
        batchMax: 1,
      },
    ),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: { ...el.dataset },
    render: (h) => h(ReleaseIndexApp),
  });
};
