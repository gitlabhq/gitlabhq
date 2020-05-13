import Home from '../pages/home.vue';
import Success from '../pages/success.vue';

import { HOME_ROUTE, SUCCESS_ROUTE } from './constants';

export default [
  {
    ...HOME_ROUTE,
    path: '/',
    component: Home,
  },
  {
    ...SUCCESS_ROUTE,
    path: '/success',
    component: Success,
  },
  {
    path: '*',
    redirect: HOME_ROUTE,
  },
];
