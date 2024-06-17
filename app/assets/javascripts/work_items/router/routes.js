import DesignDetail from '../components/design_management/design_preview/design_details.vue';
import { DESIGN_ROUTE_NAME } from '../constants';

function getRoutes() {
  const routes = [
    {
      path: '/:iid',
      name: 'workItem',
      component: () => import('../pages/work_item_root.vue'),
      props: true,
      children: [
        {
          name: DESIGN_ROUTE_NAME,
          path: 'designs/:id',
          component: DesignDetail,
          beforeEnter({ params: { id } }, _, next) {
            if (typeof id === 'string') {
              next();
            }
          },
          props: ({ params: { id, iid } }) => ({ id, iid }),
        },
      ],
    },
  ];

  if (gon.features?.workItemsAlpha) {
    routes.unshift({
      path: '/new',
      name: 'createWorkItem',
      component: () => import('../pages/create_work_item.vue'),
    });
  }

  return routes;
}

export const routes = getRoutes;
