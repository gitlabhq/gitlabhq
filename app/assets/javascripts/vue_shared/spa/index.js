import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { activeNavigationWatcher } from './utils';
import breadcrumbs from './components/spa_breadcrumbs.vue';
import RootComponent from './components/spa_root.vue';

export const initSinglePageApplication = ({
  name = 'SinglePageApplication',
  el,
  router,
  apolloCacheConfig = {},
  provide,
  propsData,
  // Any additional property to pass can go in options
  options = {},
}) => {
  if (!el) {
    throw new Error('You must provide a `el` prop to initSinglePageApplication');
  }

  if (!router) {
    throw new Error('You must provide a `router` prop to initSinglePageApplication');
  }

  let apolloProvider;

  // To not have an apollo cache, explicitly pass null
  if (apolloCacheConfig) {
    Vue.use(VueApollo);

    apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(apolloCacheConfig),
    });
  }
  router.beforeEach(activeNavigationWatcher);

  injectVueAppBreadcrumbs(router, breadcrumbs, apolloProvider);

  return new Vue({
    el,
    name,
    router,
    apolloProvider,
    provide,
    propsData,
    ...options,
    render(h) {
      return h(RootComponent, { props: propsData });
    },
  });
};
