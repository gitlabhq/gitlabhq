import { getK8sPods } from '../helpers/resolver_helpers';
import k8sDashboardPodsQuery from '../queries/k8s_dashboard_pods.query.graphql';

export default {
  k8sPods(_, { configuration }, { client }) {
    const query = k8sDashboardPodsQuery;
    return getK8sPods({ client, query, configuration });
  },
};
