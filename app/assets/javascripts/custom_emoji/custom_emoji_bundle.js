import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import defaultClient from './graphql_client';
import routes from './routes';
import App from './components/app.vue';

export const initCustomEmojis = () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const el = document.getElementById('js-custom-emojis-root');

  if (!el) return;

  const apolloProvider = new VueApollo({
    defaultClient,
  });
  const router = new VueRouter({
    base: el.dataset.basePath,
    mode: 'history',
    routes,
  });
  const { groupPath } = el.dataset;

  initVueApp({
    el,
    name: 'CustomEmojiApp',
    router,
    apolloProvider,
    provide: {
      groupPath,
    },
    component: App,
  });
};
