import Vue from 'vue';
import Vuex from 'vuex';
import ReleaseListApp from './components/app_index.vue';
import createStore from './stores';
import createListModule from './stores/modules/list';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-releases-page');

  return new Vue({
    el,
    store: createStore({
      modules: {
        list: createListModule(el.dataset),
      },
      featureFlags: {
        graphqlReleaseData: Boolean(gon.features?.graphqlReleaseData),
        graphqlReleasesPage: Boolean(gon.features?.graphqlReleasesPage),
        graphqlMilestoneStats: Boolean(gon.features?.graphqlMilestoneStats),
      },
    }),
    render: h => h(ReleaseListApp),
  });
};
