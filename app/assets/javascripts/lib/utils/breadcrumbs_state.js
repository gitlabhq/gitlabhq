import { observable } from '~/lib/utils/observable';

export const staticBreadcrumbs = observable('static_breadcrumbs', {
  items: [],
  hasInjectedBreadcrumbs: false,
});
