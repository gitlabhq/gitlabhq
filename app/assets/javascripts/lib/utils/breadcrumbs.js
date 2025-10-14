import Vue from 'vue';
import { destroySuperSidebarBreadcrumbs } from '~/super_sidebar/super_sidebar_breadcrumbs';
import { staticBreadcrumbs } from './breadcrumbs_state';

export const injectVueAppBreadcrumbs = (
  router,
  BreadcrumbsComponent,
  apolloProvider = null,
  provide = {},
  // eslint-disable-next-line max-params
) => {
  const injectBreadcrumbEl = document.querySelector('#js-injected-page-breadcrumbs');

  if (!injectBreadcrumbEl) {
    return false;
  }

  destroySuperSidebarBreadcrumbs();

  const { items } = staticBreadcrumbs;

  return new Vue({
    el: injectBreadcrumbEl,
    name: 'CustomBreadcrumbsRoot',
    router,
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(BreadcrumbsComponent, {
        class: injectBreadcrumbEl.className,
        props: {
          allStaticBreadcrumbs: items.slice(),
          // Use if your app is replacing the last breadcrumb item as root
          staticBreadcrumbs: items.slice(0, -1),
        },
      });
    },
  });
};
