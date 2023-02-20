import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import routes from './routes';
import App from './components/app.vue';

export const initSavedReplies = () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const el = document.getElementById('js-saved-replies-root');
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });
  const router = new VueRouter({
    base: el.dataset.basePath,
    mode: 'history',
    routes,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    router,
    apolloProvider,
    render(h) {
      return h(App);
    },
  });
};
