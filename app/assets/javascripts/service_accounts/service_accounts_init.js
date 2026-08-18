import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import { parseBoolean } from '~/lib/utils/common_utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import ServiceAccountsBreadcrumb from './components/service_accounts_breadcrumb.vue';

import createRouter from './router';
import app from './service_accounts_app.vue';

export default (el) => {
  if (!el) {
    return null;
  }

  const {
    basePath,
    serviceAccountsEnabled,
    serviceAccountsPath,
    serviceAccountsDeletePath,
    serviceAccountsDocsPath,
    serviceAccountsEditPath,
    accessTokenMaxDate,
    accessTokenMinDate,
    accessTokenAvailableScopes,
    accessTokenCreate,
    accessTokenRevoke,
    accessTokenRotate,
    accessTokenShow,
  } = el.dataset;

  const router = createRouter(basePath);

  injectVueAppBreadcrumbs(router, ServiceAccountsBreadcrumb);

  return initVueApp({
    el,
    name: 'ServiceAccountsRoot',
    router,
    pinia,
    provide: {
      serviceAccountsEnabled: parseBoolean(serviceAccountsEnabled),
      serviceAccountsPath,
      serviceAccountsDeletePath,
      serviceAccountsDocsPath,
      serviceAccountsEditPath,
      accessTokenMaxDate,
      accessTokenMinDate,
      accessTokenAvailableScopes: JSON.parse(accessTokenAvailableScopes),
      accessTokenCreate,
      accessTokenRevoke,
      accessTokenRotate,
      accessTokenShow,
    },
    component: app,
  });
};
