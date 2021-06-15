import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createDefaultClient from '~/lib/graphql';
import ReleaseIndexApp from './components/app_index.vue';
import ReleaseIndexApollopClientApp from './components/app_index_apollo_client.vue';
import createStore from './stores';
import createIndexModule from './stores/modules/index';

export default () => {
  const el = document.getElementById('js-releases-page');

  if (window.gon?.features?.releasesIndexApolloClient) {
    Vue.use(VueApollo);

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
          assumeImmutableResults: true,
        },
      ),
    });

    return new Vue({
      el,
      apolloProvider,
      provide: { ...el.dataset },
      render: (h) => h(ReleaseIndexApollopClientApp),
    });
  }

  Vue.use(Vuex);

  return new Vue({
    el,
    store: createStore({
      modules: {
        index: createIndexModule(el.dataset),
      },
    }),
    render: (h) => h(ReleaseIndexApp),
  });
};
