import WorkItemList from 'ee_else_ce/work_items/pages/work_items_list_app.vue';
import CreateWorkItem from '../pages/create_work_item.vue';
import WorkItemDetail from '../pages/work_item_root.vue';
import DesignDetail from '../components/design_management/design_preview/design_details.vue';
import { ROUTES, WORK_ITEM_BASE_ROUTE_MAP } from '../constants';

function generateTypeRegex(routeMap) {
  const types = Object.keys(routeMap);
  return types.join('|');
}

function getRoutes() {
  const routes = [
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})`,
      name: ROUTES.index,
      component: WorkItemList,
    },
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})/new`,
      name: ROUTES.new,
      component: CreateWorkItem,
      props: ({ params: { type }, query }) => ({
        workItemTypeName: query.type || WORK_ITEM_BASE_ROUTE_MAP[type],
      }),
    },
    {
      path: `/:type(${generateTypeRegex(WORK_ITEM_BASE_ROUTE_MAP)})/:iid`,
      name: ROUTES.workItem,
      component: WorkItemDetail,
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

  return routes;
}

export const routes = getRoutes;
