import Vue from 'vue';
import TableOfContents from '~/blob/components/table_contents.vue';

export default function initTableOfContentsApp() {
  const tableContentsEl = document.querySelector('.js-table-contents');
  if (!tableContentsEl) return null;

  return new Vue({
    el: tableContentsEl,
    name: 'BlobTableOfContentsRoot',
    render(h) {
      return h(TableOfContents);
    },
  });
}
