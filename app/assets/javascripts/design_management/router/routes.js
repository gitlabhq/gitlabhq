import Home from '../pages/index.vue';
import DesignDetail from '../pages/design/index.vue';
import { ROOT_ROUTE_NAME, DESIGNS_ROUTE_NAME, DESIGN_ROUTE_NAME } from './constants';

export default [
  {
    name: ROOT_ROUTE_NAME,
    path: '/',
    component: Home,
    meta: {
      el: 'discussion',
    },
  },
  {
    name: DESIGNS_ROUTE_NAME,
    path: '/designs',
    component: Home,
    meta: {
      el: 'designs',
    },
    children: [
      {
        name: DESIGN_ROUTE_NAME,
        path: ':id',
        component: DesignDetail,
        meta: {
          el: 'designs',
        },
        beforeEnter(
          {
            params: { id },
          },
          from,
          next,
        ) {
          if (typeof id === 'string') {
            next();
          }
        },
        props: ({ params: { id } }) => ({ id }),
      },
    ],
  },
];
