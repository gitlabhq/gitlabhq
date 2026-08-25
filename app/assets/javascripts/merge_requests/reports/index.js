import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import routes from './routes';
import MergeRequestReportsApp from './components/app.vue';

export default () => {
  Vue.use(VueRouter);
  Vue.use(VueApollo);

  const el = document.getElementById('js-reports-tab');
  const { projectPath, iid, basePath } = el.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        typePolicies: {
          Query: {
            fields: {
              project: {
                merge: true,
              },
            },
          },
        },
      },
    ),
  });
  const router = new VueRouter({
    base: basePath,
    mode: 'history',
    routes,
  });

  initVueApp({
    el,
    name: 'MergeRequestReportsAppRoot',
    router,
    apolloProvider,
    provide: {
      projectPath,
      iid,
      dismissalDescriptions: JSON.parse(window.gl?.mrWidgetData?.dismissal_descriptions || '{}'),
    },
    component: MergeRequestReportsApp,
  });
};
