import { memoize } from 'lodash-es';
import Vue from 'vue';

// Async import component since we might not need it...
const loadMarkdownTable = memoize(
  () => import(/* webpackChunkName: 'gfm_markdown_table' */ '../components/markdown_table.vue'),
);

const APPLIED_ATTRIBUTE = 'data-markdown-table-applied';
const MAX_SORTABLE_ROWS = 1000;

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
      entry.table.removeAttribute(APPLIED_ATTRIBUTE);
      mountedApps.delete(entry);
    });

    if (mountedApps.size === 0) {
      removalObserver.disconnect();
      removalObserver = null;
    }
  });

  removalObserver.observe(document.body, { childList: true, subtree: true });
}

const cellsOf = (row) => Array.from(row.cells);
const rowsOf = (section) => Array.from(section.rows);
const isHeaderRow = (row) =>
  row.cells.length > 0 && cellsOf(row).every((cell) => cell.tagName === 'TH');
const hasSpan = (row) => cellsOf(row).some((cell) => cell.colSpan !== 1 || cell.rowSpan !== 1);
const toItems = (rows) => rows.map((row, rowIndex) => ({ cells: cellsOf(row), rowIndex }));
const isNested = (table) => table.parentElement.closest('table, .md').tagName === 'TABLE';

function isClaimable(table) {
  return (
    !table.hasAttribute(APPLIED_ATTRIBUTE) &&
    table.parentNode &&
    !('tableFields' in table.dataset) &&
    !isNested(table)
  );
}

function parseTable(table) {
  const sections = Array.from(table.children);
  const rowsIn = (tagName) => sections.filter((el) => el.tagName === tagName).flatMap(rowsOf);

  const headRows = rowsIn('THEAD');
  const bodies = sections.filter((el) => el.tagName === 'TBODY').map(rowsOf);
  const footRows = rowsIn('TFOOT');
  const [firstBody = []] = bodies;
  const firstNonHeaderIndex = firstBody.findIndex((row) => !isHeaderRow(row));
  const leadingHeaderRows = firstBody.slice(
    0,
    firstNonHeaderIndex === -1 ? firstBody.length : firstNonHeaderIndex,
  );
  const headerRows = [...headRows, ...leadingHeaderRows];
  const bodyRowCount = bodies.flat().length - leadingHeaderRows.length;

  const sortable =
    headerRows.length === 1 &&
    bodies.length === 1 &&
    bodyRowCount >= 2 &&
    bodyRowCount <= MAX_SORTABLE_ROWS &&
    ![...headRows, ...firstBody, ...footRows].some(hasSpan);

  const { dir = null, ...tableAttributes } = Object.fromEntries(
    Array.from(table.attributes, ({ name, value }) => [name, value]),
  );
  const common = {
    footerRows: footRows.map(cellsOf),
    caption: table.caption,
    dir,
    tableAttributes,
  };

  if (!sortable) {
    return { ...common, fields: [], headRows: headRows.map(cellsOf), bodies: bodies.map(toItems) };
  }

  const fields = cellsOf(headerRows[0]).map((cell, index) => ({ key: `col_${index}`, cell }));
  const items = toItems(firstBody.slice(leadingHeaderRows.length)).map((item) => ({
    ...item,
    ...Object.fromEntries(
      fields.map(({ key }, index) => [key, { text: item.cells[index]?.textContent.trim() ?? '' }]),
    ),
  }));

  return { ...common, fields, headRows: [], bodies: [items] };
}

/**
 * Replace each table with the component that renders it.
 *
 * @param {Element[]} els - Candidate `.md table:not(.code)` elements.
 * @returns {?Promise} Resolves once every table has been replaced, or `null` when
 *   there is nothing to render.
 */
export default function renderMarkdownTables(els) {
  const claimed = els.filter(isClaimable).map((table) => {
    const props = parseTable(table);
    table.setAttribute(APPLIED_ATTRIBUTE, 'true');
    return { table, props };
  });

  if (!claimed.length) {
    return null;
  }

  return loadMarkdownTable().then(({ default: MarkdownTable }) => {
    claimed.forEach(({ table, props }) => {
      if (!table.parentNode) {
        table.removeAttribute(APPLIED_ATTRIBUTE);
        return;
      }

      const app = new Vue({
        el: table,
        name: 'MarkdownTableRoot',
        render: (h) => h(MarkdownTable, { props }),
      });

      observeRemoval(table, app);
    });
  });
}
