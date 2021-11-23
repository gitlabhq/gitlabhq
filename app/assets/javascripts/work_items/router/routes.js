export const routes = [
  {
    path: '/new',
    name: 'createWorkItem',
    component: () => import('../pages/create_work_item.vue'),
  },
  {
    path: '/:id',
    name: 'workItem',
    component: () => import('../pages/work_item_root.vue'),
    props: true,
  },
];
