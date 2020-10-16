import Vue from 'vue';
import Vuex from 'vuex';
import ReleaseShowApp from './components/app_show.vue';
import createStore from './stores';
import createDetailModule from './stores/modules/detail';

Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-show-release-page');

  const store = createStore({
    modules: {
      detail: createDetailModule(el.dataset),
    },
    featureFlags: {
      graphqlIndividualReleasePage: Boolean(gon.features?.graphqlIndividualReleasePage),
    },
  });

  return new Vue({
    el,
    store,
    render: h => h(ReleaseShowApp),
  });
};
