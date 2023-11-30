export const COMPONENTS = {
  conflict: () => import('./conflicts.vue'),
  discussions_not_resolved: () => import('./unresolved_discussions.vue'),
  need_rebase: () => import('./rebase.vue'),
  default: () => import('./message.vue'),
};
