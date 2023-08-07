import IndexComponent from './pages/index.vue';
import NewComponent from './pages/new.vue';
import userPermissionsQuery from './queries/user_permissions.query.graphql';
import defaultClient from './graphql_client';

export default [
  {
    path: '/',
    component: IndexComponent,
  },
  {
    path: '/new',
    component: NewComponent,
    async beforeEnter(to, from, next) {
      const {
        data: {
          group: {
            userPermissions: { createCustomEmoji },
          },
        },
      } = await defaultClient.query({
        query: userPermissionsQuery,
        variables: {
          groupPath: document.body.dataset.groupFullPath,
        },
      });

      if (!createCustomEmoji) {
        next({ path: '/' });
      } else {
        next();
      }
    },
  },
];
