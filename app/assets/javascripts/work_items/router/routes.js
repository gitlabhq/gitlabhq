export const routes = [
  {
    path: '/:id',
    name: 'work_item',
    component: () => import('../pages/work_item_root.vue'),
    props: true,
  },
];
