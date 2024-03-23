import Vue from 'vue';

// TODO: Review replacing this when a breadcrumbs ViewComponent has been created https://gitlab.com/gitlab-org/gitlab/-/issues/367326
export const injectVueAppBreadcrumbs = (router, BreadcrumbsComponent, apolloProvider = null) => {
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
