import { s__ } from '~/locale';
import PodsPage from '../pages/pods_page.vue';
import DeploymentsPage from '../pages/deployments_page.vue';
import StatefulSetsPage from '../pages/stateful_sets_page.vue';
import ReplicaSetsPage from '../pages/replica_sets_page.vue';
import {
  PODS_ROUTE_NAME,
  PODS_ROUTE_PATH,
  DEPLOYMENTS_ROUTE_NAME,
  DEPLOYMENTS_ROUTE_PATH,
  STATEFUL_SETS_ROUTE_NAME,
  STATEFUL_SETS_ROUTE_PATH,
  REPLICA_SETS_ROUTE_NAME,
  REPLICA_SETS_ROUTE_PATH,
} from './constants';

export default [
  {
    name: PODS_ROUTE_NAME,
    path: PODS_ROUTE_PATH,
    component: PodsPage,
    meta: {
      title: s__('KubernetesDashboard|Pods'),
    },
  },
  {
    name: DEPLOYMENTS_ROUTE_NAME,
    path: DEPLOYMENTS_ROUTE_PATH,
    component: DeploymentsPage,
    meta: {
      title: s__('KubernetesDashboard|Deployments'),
    },
  },
  {
    name: STATEFUL_SETS_ROUTE_NAME,
    path: STATEFUL_SETS_ROUTE_PATH,
    component: StatefulSetsPage,
    meta: {
      title: s__('KubernetesDashboard|StatefulSets'),
    },
  },
  {
    name: REPLICA_SETS_ROUTE_NAME,
    path: REPLICA_SETS_ROUTE_PATH,
    component: ReplicaSetsPage,
    meta: {
      title: s__('KubernetesDashboard|ReplicaSets'),
    },
  },
];
