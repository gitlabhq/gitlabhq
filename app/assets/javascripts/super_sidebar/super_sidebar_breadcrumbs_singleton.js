// Super sidebar breadcrumbs can be destroyed from Vue 3 context while super sidebar is running in Vue 2
// This singleton allows destroy method to locate Vue 2 app correctly

let superSidebarBreadcrumbsApp = null;

export function registerSuperSidebarBreadcrumbs(app) {
  superSidebarBreadcrumbsApp = app;
}

export function getSuperSidebarBreadcrumbs() {
  return superSidebarBreadcrumbsApp;
}
