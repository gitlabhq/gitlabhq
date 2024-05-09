import Vue from 'vue';

export const staticBreadcrumbs = Vue.observable({});

export const injectVueAppBreadcrumbs = (router, BreadcrumbsComponent, apolloProvider = null) => {
  if (gon.features.vuePageBreadcrumbs) {
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
      render(createElement) {
        return createElement(BreadcrumbsComponent, {
          class: injectBreadcrumbEl.className,
        });
      },
    });
  }

  const breadcrumbEls = document.querySelectorAll('nav .js-breadcrumbs-list li');

  if (breadcrumbEls.length < 1) {
    return false;
  }

  const breadcrumbEl = breadcrumbEls[breadcrumbEls.length - 1];

  // Allow element to grow. GlBreadcrumb would otherwise not take all available space
  // but show some of its items unnecessarily in the collapse dropdown.
  breadcrumbEl.classList.add('gl-flex-grow-1');

  const lastCrumb = breadcrumbEl.children[0];
  const nestedBreadcrumbEl = document.createElement('div');

  breadcrumbEl.replaceChild(nestedBreadcrumbEl, lastCrumb);

  return new Vue({
    el: nestedBreadcrumbEl,
    router,
    apolloProvider,
    render(createElement) {
      return createElement(BreadcrumbsComponent, {
        class: breadcrumbEl.className,
      });
    },
  });
};
