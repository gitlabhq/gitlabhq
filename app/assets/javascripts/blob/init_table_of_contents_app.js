import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import TableOfContents from '~/blob/components/table_contents.vue';

export default function initTableOfContentsApp() {
  const tableContentsEl = document.querySelector('.js-table-contents');
  if (!tableContentsEl) return null;

  return initVueApp({
    el: tableContentsEl,
    name: 'BlobTableOfContentsRoot',
    component: TableOfContents,
  });
}
