import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import { createStore } from './stores';
import PackagesListApp from './components/packages_list_app.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);
Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-vue-packages-list');
  const store = createStore();
  store.dispatch('setInitialState', el.dataset);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    store,
    apolloProvider,
    components: {
      PackagesListApp,
    },
    render(createElement) {
      return createElement('packages-list-app');
    },
  });
};
