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

const router = new VueRouter({
  mode: 'history',
  base: '/-/ide',
  routes: [
    {
      path: '/project/:namespace/:project',
      beforeEnter: (to, from, next) => {
        console.log('To Project : ' + JSON.stringify(to.params));

        store.dispatch('getProjectData', {
          namespace: to.params.namespace,
          projectId: to.params.project,
        }).then(() => {
          next();
        })
        .catch(() => {
          alert('ERROR LOADING PROJECT');
          next(false);
        });
      },
      children: [
        {
          path: 'blob/:branch',
          beforeEnter: (to, from, next) => {
            console.log('To File List : ', to.params);
            store.dispatch('getTreeData', {
              namespace: to.params.namespace,
              projectId: to.params.project,
              branch: to.params.branch,
              endpoint: '/h5bp/html5-boilerplate/tree/master',
            });
            next();
          },
          children: [
            {
              path: '*',
              beforeEnter: (to, from, next) => {
                console.log('To Selected File : ', to.params);
                next();
              },
            },
          ],
        },
        {
          // UserPosts will be rendered inside User's <router-view>
          // when /user/:id/posts is matched
          path: 'mr/:mrid',
          beforeEnter: (to, from, next) => {
            console.log('To MR : ', to.params);
            next();
          },
        },
      ],
    },
  ],
});

console.log('INIT ROUTER');

router.beforeEach((to, from, next) => {
  console.log('Routing : ',to);
  next();
})

export default router;
