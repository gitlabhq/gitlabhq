import { memoize } from 'lodash-es';
import Vue from 'vue';

// Async import component since we might not need it...
const MarkdownTable = memoize(
  () => import(/* webpackChunkName: 'gfm_markdown_table' */ '../components/markdown_table.vue'),
);

const mountedTables = new WeakMap();

function cellContent(cell) {
  return {
    html: cell ? cell.innerHTML : '',
    text: cell ? cell.textContent.trim() : '',
  };
}

// Read the rendered markdown <table> into a data model the component understands.
// Cell `html` preserves the rendered markdown (links, code, emoji, ...), while
// `text` is used for sorting comparisons.
//
// The header comes from <thead> when present. Some markdown tables omit <thead>
// and use the first <tbody> row as the header instead, so we fall back to that.
function parseTable(table) {
  const thead = table.querySelector('thead');
  const tbody = table.querySelector('tbody');

  if (!thead && !tbody) return null;

  let headerRow;
  let bodyRows;

  if (thead) {
    headerRow = thead.querySelector('tr');
    bodyRows = tbody ? Array.from(tbody.querySelectorAll('tr')) : [];
  } else {
    const rows = Array.from(tbody.querySelectorAll('tr'));
    [headerRow] = rows;
    bodyRows = rows.slice(1);
  }

  if (!headerRow) return null;

  // Header cells may be <th> (from <thead>) or <td> (first <tbody> row).
  const headerCells = Array.from(headerRow.querySelectorAll('th, td'));
  if (headerCells.length === 0) return null;

  const fields = headerCells.map((cell, index) => ({
    key: `col_${index}`,
    label: cell.innerHTML,
    isSortable: true,
  }));

  const items = bodyRows.map((row, rowIndex) => {
    const cells = Array.from(row.querySelectorAll('th, td'));
    const item = {};
    fields.forEach((field, index) => {
      item[field.key] = cellContent(cells[index]);
    });
    item.rowIndex = rowIndex;
    return item;
  });

  return { fields, items };
}

export default function renderMarkdownTables(els) {
  const isSticky = window.gon?.features?.editorStickyTableHeaders;
  const isSortable = window.gon?.features?.markdownSortableTableColumns;

  if (!isSticky && !isSortable) {
    return;
  }

  els.forEach((table) => {
    if (mountedTables.has(table)) return;
    if (!table.parentNode) return;

    const parsed = parseTable(table);
    if (!parsed) return;

    const { fields, items } = parsed;

    const app = new Vue({
      el: table,
      name: 'MarkdownTableRoot',
      render: (h) => h(MarkdownTable, { props: { fields, items, isSortable, isSticky } }),
    });

    mountedTables.set(table, app);
  });
}
