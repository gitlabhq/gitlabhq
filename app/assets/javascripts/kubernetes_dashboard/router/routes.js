import { s__ } from '~/locale';
import PodsPage from '../pages/pods_page.vue';
import DeploymentsPage from '../pages/deployments_page.vue';
import {
  PODS_ROUTE_NAME,
  PODS_ROUTE_PATH,
  DEPLOYMENTS_ROUTE_NAME,
  DEPLOYMENTS_ROUTE_PATH,
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
];
