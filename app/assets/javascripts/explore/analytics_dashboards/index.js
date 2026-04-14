import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import AnalyticsDashboardsApp from './components/app.vue';

export default () => {
  const el = document.getElementById('js-explore-analytics-dashboards');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const organizationId = convertToGraphQLId(TYPE_ORGANIZATION, gon.current_organization?.id);
  const currentUserId = gon.current_user_id;

  return new Vue({
    el,
    name: 'AnalyticsDashboardsRoot',
    apolloProvider,
    render(h) {
      return h(AnalyticsDashboardsApp, {
        props: {
          organizationId,
          currentUserId,
        },
      });
    },
  });
};
