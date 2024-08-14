import Vue from 'vue';

export const staticBreadcrumbs = Vue.observable({});

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

  // Hide the last of the static breadcrumbs by nulling its values.
  // This way, the separator "/" stays visible and also the new "last" static item isn't displayed in bold font.
  staticBreadcrumbs.items[staticBreadcrumbs.items.length - 1].text = '';
  staticBreadcrumbs.items[staticBreadcrumbs.items.length - 1].href = '';

  return new Vue({
    el: injectBreadcrumbEl,
    router,
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(BreadcrumbsComponent, {
        class: injectBreadcrumbEl.className,
      });
    },
  });
};
