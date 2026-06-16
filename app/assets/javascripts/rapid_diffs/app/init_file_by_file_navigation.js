import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import FileByFileNavigation from './file_by_file_navigation.vue';

export function initFileByFileNavigation(el) {
  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'FileByFileNavigationRoot',
    pinia,
    render(h) {
      return h(FileByFileNavigation);
    },
  });
}
