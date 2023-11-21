import { s__ } from '~/locale';
import { PODS_ROUTE_NAME, PODS_ROUTE_PATH } from './constants';

export default [
  {
    name: PODS_ROUTE_NAME,
    path: PODS_ROUTE_PATH,
    meta: {
      title: s__('KubernetesDashboard|Pods'),
    },
  },
];
