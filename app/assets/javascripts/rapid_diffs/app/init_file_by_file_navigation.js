import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import FileByFileNavigation from './file_by_file_navigation.vue';

export function initFileByFileNavigation(el) {
  if (!el) return;

  initVueApp({ el, name: 'FileByFileNavigationRoot', pinia, component: FileByFileNavigation });
}
