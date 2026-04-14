import Vue from 'vue';
import { destroySuperSidebarBreadcrumbs } from '~/super_sidebar/super_sidebar_breadcrumbs';
import { staticBreadcrumbs } from './breadcrumbs_state';

// eslint-disable-next-line max-params
function injectIntoTopbar(router, BreadcrumbsComponent, apolloProvider, provide) {
  const slotEl = document.querySelector('#js-super-topbar-breadcrumbs-slot');

  if (!slotEl) {
    return false;
  }

  const { items } = staticBreadcrumbs;

  const mountEl = document.createElement('div');
  slotEl.appendChild(mountEl);

  const injectedBreadcrumbsApp = new Vue({
    el: mountEl,
    name: 'InjectedBreadcrumbsRoot',
    router,
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(BreadcrumbsComponent, {
        class: slotEl.className,
        props: {
          allStaticBreadcrumbs: items.slice(),
          staticBreadcrumbs: items.slice(0, -1),
        },
      });
    },
  });

  staticBreadcrumbs.hasInjectedBreadcrumbs = true;
  return injectedBreadcrumbsApp;
}

export const injectVueAppBreadcrumbs = (
  router,
  BreadcrumbsComponent,
  apolloProvider = null,
  provide = {},
  // eslint-disable-next-line max-params
) => {
  if (gon.features?.pageBreadcrumbsInTopBar) {
    return injectIntoTopbar(router, BreadcrumbsComponent, apolloProvider, provide);
  }

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
