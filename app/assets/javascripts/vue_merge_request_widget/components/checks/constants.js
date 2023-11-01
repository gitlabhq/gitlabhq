export const COMPONENTS = {
  conflict: () => import('./conflicts.vue'),
  unresolved_discussions: () => import('./unresolved_discussions.vue'),
  need_rebase: () => import('./rebase.vue'),
  default: () => import('./message.vue'),
};
