import Vue from 'vue';
import { destroySuperSidebarBreadcrumbs } from '~/super_sidebar/super_sidebar_breadcrumbs';
import { staticBreadcrumbs } from './breadcrumbs_state';

export const injectVueAppBreadcrumbs = (
  router,
  BreadcrumbsComponent,
  apolloProvider = null,
  provide = {},
  // this is intended to be a temporary option. Once all uses of
  // injectVueAppBreadcrumbs use it, the option should be removed and its
  // behavior should be the default.
  // Cf. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186906
  { singleNavOptIn = false } = {},
  // eslint-disable-next-line max-params
) => {
  const injectBreadcrumbEl = document.querySelector('#js-injected-page-breadcrumbs');

  if (!injectBreadcrumbEl) {
    return false;
  }

  if (singleNavOptIn) {
    destroySuperSidebarBreadcrumbs();
    // After singleNavOptIn is turned on for all Vue apps, we can stop
    // changing the content of staticBreadcrumbs and instead pass a mutated
    // copy of it to the CustomBreadcrumbsRoot component. For now, we need
    // to conditionally mutate the staticBreadcrumbs object so that the last
    // breadcrumb is hidden for Vue apps that have not opted in to the
    // singleNavOptIn.
    // Cf. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186906
    staticBreadcrumbs.items = staticBreadcrumbs.items.slice(0, -1);
  } else {
    // Hide the last of the static breadcrumbs by nulling its values.
    // This way, the separator "/" stays visible and also the new "last" static item isn't displayed in bold font.
    staticBreadcrumbs.items[staticBreadcrumbs.items.length - 1].text = '';
    staticBreadcrumbs.items[staticBreadcrumbs.items.length - 1].href = '';
  }

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
          staticBreadcrumbs,
        },
      });
    },
  });
};
