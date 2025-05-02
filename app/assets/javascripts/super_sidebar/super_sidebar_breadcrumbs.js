import Vue from 'vue';
import { GlBreadcrumb } from '@gitlab/ui';
import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs_state';

let superSidebarBreadcrumbsApp = null;

export function initPageBreadcrumbs() {
  const el = document.querySelector('#js-vue-page-breadcrumbs');
  if (!el) return false;
  const { breadcrumbsJson } = el.dataset;

  staticBreadcrumbs.items = JSON.parse(breadcrumbsJson);

  superSidebarBreadcrumbsApp = new Vue({
    el,
    name: 'SuperSidebarBreadcrumbs',
    destroyed() {
      this.$el?.remove();
      superSidebarBreadcrumbsApp = null;
    },
    render(h) {
      return h(GlBreadcrumb, {
        props: staticBreadcrumbs,
      });
    },
  });

  return superSidebarBreadcrumbsApp;
}

export function destroySuperSidebarBreadcrumbs() {
  if (superSidebarBreadcrumbsApp) {
    superSidebarBreadcrumbsApp.$destroy();
  }
}
