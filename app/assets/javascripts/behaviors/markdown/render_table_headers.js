import { STICKY_HEADER_CLASSES } from '~/lib/utils/table_sticky_header';

export default function renderStickyTableHeaders(els) {
  if (!window.gon?.features?.editorStickyTableHeaders) return;

  els.forEach((table) => {
    if (
      table.closest(
        '[data-sticky-header], .gl-table-shadow, .ProseMirror, .tableWrapper, .rd-text-view-root',
      )
    ) {
      return;
    }

    const wrapper = document.createElement('div');
    wrapper.dataset.stickyHeader = '';
    wrapper.classList.add(...STICKY_HEADER_CLASSES);
    table.classList.add('!gl-my-0');
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  });
}
