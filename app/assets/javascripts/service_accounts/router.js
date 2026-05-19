import Vue from 'vue';
import VueRouter from 'vue-router';

import AccessTokens from '~/vue_shared/access_tokens/components/access_tokens.vue';
import ServiceAccounts from './components/service_accounts.vue';
import { ROUTES } from './constants';

Vue.use(VueRouter);

export default (base) => {
  const routes = [
    { path: '/', name: ROUTES.index, component: ServiceAccounts },
    {
      path: '/:id/access_tokens',
      name: ROUTES.accessTokens,
      component: AccessTokens,
      props: ({ params: { id } }) => {
        return { id: Number(id), showAvatar: true };
      },
    },
  ];

  const router = new VueRouter({
    mode: 'history',
    base,
    routes,
  });

  return router;
};
