import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import ReleaseIndexApp from './components/app_index.vue';

export default () => {
  const el = document.getElementById('js-releases-page');

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'ReleaseIndexAppRoot',
    apolloProvider,
    provide: { ...el.dataset },
    component: ReleaseIndexApp,
  });
};
