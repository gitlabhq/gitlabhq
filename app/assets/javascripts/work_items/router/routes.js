import PlanningView from 'ee_else_ce/work_items/pages/planning_view.vue';
import CreateWorkItem from '../pages/create_work_item.vue';
import WorkItemDetail from '../pages/work_item_root.vue';
import DesignDetail from '../components/design_management/design_preview/design_details.vue';
import { ROUTES } from '../constants';

export const routes = [
  {
    path: '/:type',
    name: ROUTES.index,
    component: PlanningView,
  },
  {
    path: '/:type/views/:view_id',
    name: ROUTES.savedView,
    component: PlanningView,
  },
  {
    path: '/:type/new',
    name: ROUTES.new,
    component: CreateWorkItem,
  },
  {
    path: '/:type/:iid',
    name: ROUTES.workItem,
    component: WorkItemDetail,
    props: true,
    children: [
      {
        name: ROUTES.design,
        path: 'designs/:id?',
        component: DesignDetail,
        beforeEnter(to, _, next) {
          if (to.params.id) {
            if (typeof to.params.id === 'string') {
              next();
            }
          } else {
            // If no ID route to main work item view.
            // This supports design version notes with format /designs?version=##
            next({
              name: ROUTES.workItem,
              params: to.params,
              query: to.query,
            });
          }
        },
        props: ({ params: { id, iid } }) => ({ id, iid }),
      },
    ],
  },
];
