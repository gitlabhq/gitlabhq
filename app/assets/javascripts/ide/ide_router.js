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
  console.log('BEFORE EACH : ',to);

  store.dispatch('getProjectData', {
    namespace: to.params.namespace,
    projectId: to.params.project,
  })
  .then(() => {
    if (to.params.branch) {
      store.dispatch('getBranchData', {
        namespace: to.params.namespace,
        projectId: to.params.project,
        branch: to.params.branch,
      });

      store.dispatch('getTreeData', {
        namespace: to.params.namespace,
        projectId: to.params.project,
        branch: to.params.branch,
        endpoint: `/${to.params.namespace}/${to.params.project}/tree/${to.params.branch}`,
      })
      .then(() => {
        if (to.params[0]) {
          const treeEntry = store.getters.getTreeEntry(`${to.params.namespace}/${to.params.project}/${to.params.branch}`, to.params[0]);
          if (treeEntry) {
            console.log('To Selected File : ', to.params, '/', treeEntry.url);
            store.dispatch('handleTreeEntryAction', treeEntry);
          }
        } else {
          throw (new Error(`Tree entry for ${to.params[0]} doesn't exist`));
        }
      })
      .catch((e) => {
        debugger;
      });

      if (!to.params[0]) {
        // We are in the root of the tree
        console.log('Load Branch Tree');
      } else {
        
      }
    }
  })
  .catch((e) => {
    debugger;
    //next(false);
  });
  next();
});

export default router;
