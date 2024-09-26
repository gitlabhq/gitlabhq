import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlToast } from '@gitlab/ui';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { removeLastSlashInUrlPath } from '~/lib/utils/url_utility';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import EnvironmentBreadcrumbs from './environment_details/environment_breadcrumbs.vue';
import EnvironmentsDetailHeader from './components/environments_detail_header.vue';
import { apolloProvider as createApolloProvider } from './graphql/client';
import environmentsMixin from './mixins/environments_mixin';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = createApolloProvider();

export const initHeader = () => {
  const el = document.getElementById('environments-detail-view-header');
  const container = document.getElementById('environments-detail-view');
  const dataset = convertObjectPropsToCamelCase(JSON.parse(container.dataset.details));

  return new Vue({
    el,
    apolloProvider,
    mixins: [environmentsMixin],
    provide: {
      projectFullPath: dataset.projectFullPath,
    },
    data() {
      const environment = {
        name: dataset.name,
        id: Number(dataset.id),
        externalUrl: dataset.externalUrl,
        isAvailable: dataset.isEnvironmentAvailable,
        hasTerminals: dataset.hasTerminals,
        autoStopAt: dataset.autoStopAt,
        onSingleEnvironmentPage: true,
        // TODO: These two props are snake_case because the environments_mixin file uses
        // them and the mixin is imported in several files. It would be nice to convert them to camelCase.
        stop_path: dataset.environmentStopPath,
        delete_path: dataset.environmentDeletePath,
        descriptionHtml: dataset.descriptionHtml,
      };

      return {
        environment,
      };
    },
    render(createElement) {
      return createElement(EnvironmentsDetailHeader, {
        props: {
          environment: this.environment,
          canDestroyEnvironment: dataset.canDestroyEnvironment,
          canUpdateEnvironment: dataset.canUpdateEnvironment,
          canStopEnvironment: dataset.canStopEnvironment,
          canAdminEnvironment: dataset.canAdminEnvironment,
          cancelAutoStopPath: dataset.environmentCancelAutoStopPath,
          terminalPath: dataset.environmentTerminalPath,
          updatePath: dataset.environmentEditPath,
        },
      });
    },
  });
};

export const initPage = async () => {
  const dataElement = document.getElementById('environments-detail-view');
  const dataSet = convertObjectPropsToCamelCase(JSON.parse(dataElement.dataset.details));

  Vue.use(VueRouter);
  const el = document.getElementById('environment_details_page');

  const router = new VueRouter({
    mode: 'history',
    base: dataSet.basePath,
    routes: [
      {
        path: '/k8s/namespace/:namespace/pods/:podName/logs',
        name: 'logs',
        meta: {
          environmentName: dataSet.name,
        },
        component: () => import('./environment_details/components/kubernetes/kubernetes_logs.vue'),
        props: (route) => ({
          containerName: route.query.container,
          podName: route.params.podName,
          namespace: route.params.namespace,
          environmentName: dataSet.name,
          highlightedLineHash: (route.hash || '').replace('#', ''),
        }),
      },
      {
        path: '/',
        name: 'environment_details',
        meta: {
          environmentName: dataSet.name,
        },
        component: () => import('./environment_details/index.vue'),
        props: (route) => ({
          after: route.query.after,
          before: route.query.before,
          projectFullPath: dataSet.projectFullPath,
          environmentName: dataSet.name,
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

  injectVueAppBreadcrumbs(router, EnvironmentBreadcrumbs);

  return new Vue({
    el,
    apolloProvider,
    router,
    provide: {
      projectPath: dataSet.projectFullPath,
      graphqlEtagKey: dataSet.graphqlEtagKey,
      kasTunnelUrl: removeLastSlashInUrlPath(dataElement.dataset.kasTunnelUrl),
    },
    render(createElement) {
      return createElement('router-view');
    },
  });
};
