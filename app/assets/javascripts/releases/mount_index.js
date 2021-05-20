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
      defaultClient: createDefaultClient(),
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
