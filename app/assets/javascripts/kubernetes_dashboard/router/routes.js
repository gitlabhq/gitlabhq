import { s__ } from '~/locale';
import PodsPage from '../pages/pods_page.vue';
import DeploymentsPage from '../pages/deployments_page.vue';
import StatefulSetsPage from '../pages/stateful_sets_page.vue';
import ReplicaSetsPage from '../pages/replica_sets_page.vue';
import DaemonSetsPage from '../pages/daemon_sets_page.vue';
import JobsPage from '../pages/jobs_page.vue';
import CronJobsPage from '../pages/cron_jobs_page.vue';
import ServicesPage from '../pages/services_page.vue';

import {
  PODS_ROUTE_NAME,
  PODS_ROUTE_PATH,
  DEPLOYMENTS_ROUTE_NAME,
  DEPLOYMENTS_ROUTE_PATH,
  STATEFUL_SETS_ROUTE_NAME,
  STATEFUL_SETS_ROUTE_PATH,
  REPLICA_SETS_ROUTE_NAME,
  REPLICA_SETS_ROUTE_PATH,
  DAEMON_SETS_ROUTE_NAME,
  DAEMON_SETS_ROUTE_PATH,
  JOBS_ROUTE_NAME,
  JOBS_ROUTE_PATH,
  CRON_JOBS_ROUTE_NAME,
  CRON_JOBS_ROUTE_PATH,
  SERVICES_ROUTE_NAME,
  SERVICES_ROUTE_PATH,
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
  {
    name: DAEMON_SETS_ROUTE_NAME,
    path: DAEMON_SETS_ROUTE_PATH,
    component: DaemonSetsPage,
    meta: {
      title: s__('KubernetesDashboard|DaemonSets'),
    },
  },
  {
    name: JOBS_ROUTE_NAME,
    path: JOBS_ROUTE_PATH,
    component: JobsPage,
    meta: {
      title: s__('KubernetesDashboard|Jobs'),
    },
  },
  {
    name: CRON_JOBS_ROUTE_NAME,
    path: CRON_JOBS_ROUTE_PATH,
    component: CronJobsPage,
    meta: {
      title: s__('KubernetesDashboard|CronJobs'),
    },
  },
  {
    name: SERVICES_ROUTE_NAME,
    path: SERVICES_ROUTE_PATH,
    component: ServicesPage,
    meta: {
      title: s__('KubernetesDashboard|Services'),
    },
  },
];
