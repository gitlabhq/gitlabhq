import WorkItemList from 'ee_else_ce/work_items/pages/work_items_list_app.vue';
import DesignDetail from '../components/design_management/design_preview/design_details.vue';
import { ROUTES } from '../constants';

function getRoutes(isGroup) {
  const routes = [
    {
      path: '/:type(issues|epics|work_items)/:iid',
      name: ROUTES.workItem,
      component: () => import('../pages/work_item_root.vue'),
      props: true,
      children: [
        {
          name: ROUTES.design,
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

  if (isGroup) {
    routes.unshift({
      path: '/:type(issues|epics|work_items)',
      name: ROUTES.index,
      component: WorkItemList,
    });
  }

  if (gon.features?.workItemsAlpha) {
    routes.unshift({
      path: '/:type(issues|epics|work_items)/new',
      name: ROUTES.new,
      component: () => import('../pages/create_work_item.vue'),
    });
  }

  return routes;
}

export const routes = getRoutes;
