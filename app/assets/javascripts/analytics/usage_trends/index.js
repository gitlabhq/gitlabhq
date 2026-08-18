import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import UsageTrendsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('js-usage-trends-app');

  if (!el) return false;

  return initVueApp({ el, name: 'UsageTrendsAppRoot', apolloProvider, component: UsageTrendsApp });
};
