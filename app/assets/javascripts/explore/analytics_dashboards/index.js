import Vue from 'vue';
import VueApollo from 'vue-apollo';
import AnalyticsDashboardsBreadcrumbs from '~/analytics/shared/components/analytics_dashboards_breadcrumbs.vue';
import createDefaultClient from '~/lib/graphql';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { observable } from '~/lib/utils/observable';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import App from './pages/app.vue';
import createRouter from './router';

export default () => {
  const el = document.getElementById('js-explore-analytics-dashboards');

  if (!el) {
    return false;
  }

  const { exploreAnalyticsDashboardsPath } = convertObjectPropsToCamelCase(el.dataset);

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const currentUserId = convertToGraphQLId(TYPENAME_USER, gon.current_user_id);

  // This is a mini state to help the breadcrumb have the correct name
  const breadcrumbState = observable('explore_analytics_dashboards_breadcrumb', {
    name: '',
    updateName(value) {
      this.name = value;
    },
  });

  const router = createRouter(exploreAnalyticsDashboardsPath, breadcrumbState);
  injectVueAppBreadcrumbs(router, AnalyticsDashboardsBreadcrumbs);

  return new Vue({
    el,
    name: 'AnalyticsDashboardsRoot',
    apolloProvider,
    router,
    provide: {
      currentUserId,
      exploreAnalyticsDashboardsPath,
      breadcrumbState,
    },
    render(h) {
      return h(App);
    },
  });
};
