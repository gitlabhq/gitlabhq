function getRoutes() {
  const routes = [
    {
      path: '/:iid',
      name: 'workItem',
      component: () => import('../pages/work_item_root.vue'),
      props: true,
    },
  ];

  if (gon.features?.workItemsMvc2) {
    routes.unshift({
      path: '/new',
      name: 'createWorkItem',
      component: () => import('../pages/create_work_item.vue'),
    });
  }

  return routes;
}

export const routes = getRoutes;
