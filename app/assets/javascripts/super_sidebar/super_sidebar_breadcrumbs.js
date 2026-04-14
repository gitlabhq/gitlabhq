import Vue from 'vue';
import { GlBreadcrumb } from '@gitlab/ui';
import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs_state';
import {
  registerSuperSidebarBreadcrumbs,
  getSuperSidebarBreadcrumbs,
} from './super_sidebar_breadcrumbs_singleton';

export function initPageBreadcrumbs() {
  const el = document.querySelector('#js-vue-page-breadcrumbs');
  if (!el) return false;
  const { breadcrumbsJson } = el.dataset;

  staticBreadcrumbs.items = JSON.parse(breadcrumbsJson);

  if (gon.features?.pageBreadcrumbsInTopBar) {
    document.querySelector('.js-static-panel #js-vue-page-breadcrumbs-wrapper')?.remove();
    return false;
  }

  const superSidebarBreadcrumbsApp = new Vue({
    el,
    name: 'SuperSidebarBreadcrumbs',
    destroyed() {
      this.$el?.remove();
      registerSuperSidebarBreadcrumbs(null);
    },
    render(h) {
      return h(GlBreadcrumb, {
        props: staticBreadcrumbs,
      });
    },
  });

  registerSuperSidebarBreadcrumbs(superSidebarBreadcrumbsApp);

  return superSidebarBreadcrumbsApp;
}

export function destroySuperSidebarBreadcrumbs() {
  const superSidebarBreadcrumbsApp = getSuperSidebarBreadcrumbs();
  if (superSidebarBreadcrumbsApp) {
    superSidebarBreadcrumbsApp.$destroy();
  }
}
