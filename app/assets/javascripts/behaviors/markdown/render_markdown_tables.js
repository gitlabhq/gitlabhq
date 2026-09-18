import { memoize } from 'lodash-es';
import Vue from 'vue';

// Async import component since we might not need it...
const loadMarkdownTable = memoize(
  () => import(/* webpackChunkName: 'gfm_markdown_table' */ '../components/markdown_table.vue'),
);

const mountedApps = new Set();
let removalObserver;

function observeRemoval(table, app) {
  const mountedApp = { table, app };
  mountedApps.add(mountedApp);

  if (removalObserver) return;

  removalObserver = new MutationObserver((mutations) => {
    if (!mutations.some(({ removedNodes }) => removedNodes.length > 0)) return;

    mountedApps.forEach((entry) => {
      if (entry.app.$el.isConnected) return;

      entry.app.$destroy();
      // eslint-disable-next-line no-param-reassign
      delete entry.table.dataset.markdownTableApplied;
      mountedApps.delete(entry);
    });

    if (mountedApps.size === 0) {
      removalObserver.disconnect();
      removalObserver = null;
    }
  });

  removalObserver.observe(document.body, { childList: true, subtree: true });
}

function parseTable(table) {
  // Take care to grab only *this* table's cells, and not any nested tables'.
  const thead = table.tHead;

  // A table without a declared header (e.g. hand-authored HTML) is left as-is;
  // promoting the first body row would fabricate a header that was never authored.
  if (!thead) return null;

  const [tbody] = table.tBodies;
  const [headerRow] = thead.rows;
  const bodyRows = tbody ? Array.from(tbody.rows) : [];

  if (!headerRow) return null;

  const headerCells = Array.from(headerRow.cells);
  if (headerCells.length === 0) return null;

  const fields = headerCells.map((cell, index) => ({
    key: `col_${index}`,
    cell,
    isSortable: true,
  }));

  const items = bodyRows.map((row, rowIndex) => {
    const cells = Array.from(row.cells);
    const item = { cells, rowIndex };
    fields.forEach((field, index) => {
      item[field.key] = { text: cells[index] ? cells[index].textContent.trim() : '' };
    });
    return item;
  });

  return { fields, items };
}

/**
 * Replace each table with the component that renders it.
 *
 * @param {Element[]} els - Candidate `.md table:not(.code)` elements.
 * @returns {?Promise} Resolves once every table has been replaced, or `null` when
 *   there is nothing to render.
 */
export default function renderMarkdownTables(els) {
  const isSticky = window.gon?.features?.editorStickyTableHeaders;
  const isSortable = window.gon?.features?.markdownSortableTableColumns;

  if (!isSticky && !isSortable) {
    return null;
  }

  const claimed = [];

  els.forEach((table) => {
    if (table.dataset.markdownTableApplied === 'true') return;
    if (!table.parentNode) return;

    const parsed = parseTable(table);
    if (!parsed) return;

    // eslint-disable-next-line no-param-reassign
    table.dataset.markdownTableApplied = 'true';
    claimed.push({ table, ...parsed });
  });

  if (!claimed.length) {
    return null;
  }

  return loadMarkdownTable().then(({ default: MarkdownTable }) => {
    claimed.forEach(({ table, fields, items }) => {
      if (!table.parentNode) {
        // eslint-disable-next-line no-param-reassign
        delete table.dataset.markdownTableApplied;
        return;
      }

      const app = new Vue({
        el: table,
        name: 'MarkdownTableRoot',
        render: (h) => h(MarkdownTable, { props: { fields, items, isSortable, isSticky } }),
      });

      observeRemoval(table, app);
    });
  });
}
