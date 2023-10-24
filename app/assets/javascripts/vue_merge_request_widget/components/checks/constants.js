export const COMPONENTS = {
  conflicts: () => import('./conflicts.vue'),
  unresolved_discussions: () => import('./unresolved_discussions.vue'),
  rebase: () => import('./rebase.vue'),
  default: () => import('./message.vue'),
};
