import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import typeDefs from './typedefs.graphql';
import k8sPodsQuery from './queries/k8s_dashboard_pods.query.graphql';
import k8sDeploymentsQuery from './queries/k8s_dashboard_deployments.query.graphql';
import k8sStatefulSetsQuery from './queries/k8s_dashboard_stateful_sets.query.graphql';
import k8sReplicaSetsQuery from './queries/k8s_dashboard_replica_sets.query.graphql';
import k8sDaemonSetsQuery from './queries/k8s_dashboard_daemon_sets.query.graphql';
import k8sJobsQuery from './queries/k8s_dashboard_jobs.query.graphql';
import k8sCronJobsQuery from './queries/k8s_dashboard_cron_jobs.query.graphql';
import k8sServicesQuery from './queries/k8s_dashboard_services.query.graphql';
import { resolvers } from './resolvers';

export const apolloProvider = () => {
  const defaultClient = createDefaultClient(resolvers, {
    typeDefs,
  });
  const { cache } = defaultClient;

  const metadata = {
    name: null,
    namespace: null,
    creationTimestamp: null,
    labels: null,
    annotations: null,
  };
  const data = { nodes: { metadata, status: {}, spec: {} } };

  cache.writeQuery({
    query: k8sPodsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sDeploymentsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sStatefulSetsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sReplicaSetsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sDaemonSetsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sJobsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sCronJobsQuery,
    data,
  });

  cache.writeQuery({
    query: k8sServicesQuery,
    data,
  });

  return new VueApollo({
    defaultClient,
  });
};
