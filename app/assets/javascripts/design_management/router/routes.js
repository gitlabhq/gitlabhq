import DesignDetail from '../pages/design/index.vue';
import Home from '../pages/index.vue';
import { DESIGNS_ROUTE_NAME, DESIGN_ROUTE_NAME } from './constants';

export default [
  {
    name: DESIGNS_ROUTE_NAME,
    path: '/',
    component: Home,
    alias: '/designs',
  },
  {
    name: DESIGN_ROUTE_NAME,
    path: '/designs/:id',
    component: DesignDetail,
    beforeEnter({ params: { id } }, _, next) {
      if (typeof id === 'string') {
        next();
      }
    },
    props: ({ params: { id } }) => ({ id }),
  },
];
