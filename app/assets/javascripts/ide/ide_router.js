import Vue from 'vue';
import VueRouter from 'vue-router';
import store from './stores';

Vue.use(VueRouter);

/**
 * Routes below /-/ide/:

/project/h5bp/html5-boilerplate/blob/master
/project/h5bp/html5-boilerplate/blob/master/app/js/test.js

/project/h5bp/html5-boilerplate/mr/123
/project/h5bp/html5-boilerplate/mr/123/app/js/test.js

/workspace/123
/workspace/project/h5bp/html5-boilerplate/blob/my-special-branch
/workspace/project/h5bp/html5-boilerplate/mr/123

/ = /workspace

/settings
*/

// Unfortunately Vue Router doesn't work without at least a fake component
// If you do only data handling
const FooRouterComponent = {
  template: '<div>foo</div>',
};

const router = new VueRouter({
  mode: 'history',
  base: '/-/ide/',
  routes: [
    {
      path: '/project/:namespace/:project',
      component: FooRouterComponent,
      children: [
        {
          path: ':targetmode/:branch/*',
          component: FooRouterComponent,
        },
        {
          path: 'mr/:mrid',
          component: FooRouterComponent,
        },
      ],
    },
  ],
});

router.beforeEach((to, from, next) => {
  store.dispatch('getProjectData', {
    namespace: to.params.namespace,
    projectId: to.params.project,
  })
  .then(() => {
    const fullProjectId = `${to.params.namespace}/${to.params.project}`;

    if (to.params.branch) {
      store.dispatch('getBranchData', {
        projectId: fullProjectId,
        branchId: to.params.branch,
      });

      store.dispatch('getTreeData', {
        projectId: fullProjectId,
        branch: to.params.branch,
        endpoint: `/${fullProjectId}/tree/${to.params.branch}`,
      })
      .then(() => {
        if (to.params[0]) {
          const treeEntry = store.getters.getTreeEntry(`${to.params.namespace}/${to.params.project}/${to.params.branch}`, to.params[0]);
          if (treeEntry) {
            store.dispatch('handleTreeEntryAction', treeEntry);
          }
        } else {
          throw (new Error(`Tree entry for ${to.params[0]} doesn't exist`));
        }
      })
      .catch((e) => {
        throw e;
      });
    }
  })
  .catch((e) => {
    throw e;
  });
  next();
});

export default router;
