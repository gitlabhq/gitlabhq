import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import EnvironmentsDetailHeader from './components/environments_detail_header.vue';
import { apolloProvider } from './graphql/client';
import environmentsMixin from './mixins/environments_mixin';

export const initHeader = () => {
  const el = document.getElementById('environments-detail-view-header');
  const container = document.getElementById('environments-detail-view');
  const dataset = convertObjectPropsToCamelCase(JSON.parse(container.dataset.details));

  return new Vue({
    el,
    mixins: [environmentsMixin],
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
        // them and the mixin is imported in several files. It would be nice to conver them to camelCase.
        stop_path: dataset.environmentStopPath,
        delete_path: dataset.environmentDeletePath,
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
          metricsPath: dataset.environmentMetricsPath,
          updatePath: dataset.environmentEditPath,
        },
      });
    },
  });
};

export const initPage = async () => {
  if (!gon.features.environmentDetailsVue) {
    return null;
  }
  const EnvironmentsDetailPageModule = await import('./environment_details/index.vue');
  const EnvironmentsDetailPage = EnvironmentsDetailPageModule.default;
  const dataElement = document.getElementById('environments-detail-view');
  const dataSet = convertObjectPropsToCamelCase(JSON.parse(dataElement.dataset.details));

  Vue.use(VueApollo);
  Vue.use(VueRouter);
  const el = document.getElementById('environment_details_page');

  const router = new VueRouter({
    mode: 'history',
    base: window.location.pathname,
    routes: [
      {
        path: '/',
        name: 'environment_details',
        component: EnvironmentsDetailPage,
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

  return new Vue({
    el,
    apolloProvider: apolloProvider(),
    router,
    provide: {
      projectPath: dataSet.projectFullPath,
      graphqlEtagKey: dataSet.graphqlEtagPath,
    },
    render(createElement) {
      return createElement('router-view');
    },
  });
};
