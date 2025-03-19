import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import Translate from '~/vue_shared/translate';
import { apolloProvider } from '../graphql/client';
import EnvironmentsFolderApp from './environments_folder_app.vue';

Vue.use(Translate);
Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('environments-folder-list-view');

  if (!el) return null;

  Vue.use(VueRouter);

  const environmentsData = el.dataset;
  const folderPath = environmentsData.endpoint.replace('.json', '');
  const { projectPath, folderName, helpPagePath } = environmentsData;

  const router = new VueRouter({
    mode: 'history',
    base: window.location.pathname,
    routes: [
      {
        path: '/',
        name: 'environments_folder',
        component: EnvironmentsFolderApp,
        props: (route) => ({
          scope: route.query.scope,
          page: Number(route.query.page || '1'),
          folderName,
          folderPath,
        }),
      },
    ],
    scrollBehavior(to, from, savedPosition) {
      if (savedPosition) {
        return savedPosition;
      }
      return { top: 0 };
    },
  });

  return new Vue({
    el,
    provide: {
      projectPath,
      helpPagePath,
    },
    apolloProvider,
    router,
    render(createElement) {
      return createElement('router-view');
    },
  });
};
