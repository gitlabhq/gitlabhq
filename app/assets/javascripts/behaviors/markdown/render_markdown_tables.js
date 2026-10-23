import { memoize } from 'lodash-es';
import Vue from 'vue';

// Async import component since we might not need it...
const loadMarkdownTable = memoize(
  () => import(/* webpackChunkName: 'gfm_markdown_table' */ '../components/markdown_table.vue'),
);

const APPLIED_ATTRIBUTE = 'data-markdown-table-applied';
const MAX_SORTABLE_ROWS = 1000;
const SECTION_TAGS = ['THEAD', 'TBODY', 'TFOOT'];

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

const attributesOf = (el) =>
  Object.fromEntries(Array.from(el.attributes, ({ name, value }) => [name, value]));
const toRow = (row, rowIndex) => ({
  rowIndex,
  attributes: attributesOf(row),
  cells: Array.from(row.cells),
});
const toSection = (section) => ({
  tagName: section.tagName.toLowerCase(),
  attributes: attributesOf(section),
  rows: Array.from(section.rows, toRow),
});
const isHeaderRow = ({ cells }) => cells.length > 0 && cells.every((cell) => cell.tagName === 'TH');
const hasSpan = ({ cells }) => cells.some((cell) => cell.colSpan !== 1 || cell.rowSpan !== 1);
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
  const { dir = null, ...tableAttributes } = attributesOf(table);
  const sections = Array.from(table.children)
    .filter(({ tagName }) => SECTION_TAGS.includes(tagName))
    .map(toSection);
  const heads = sections.filter(({ tagName }) => tagName === 'thead');
  const bodies = sections.filter(({ tagName }) => tagName === 'tbody');
  const [firstBody] = bodies;
  const firstBodyRows = firstBody?.rows ?? [];
  const firstNonHeaderIndex = firstBodyRows.findIndex((row) => !isHeaderRow(row));
  const leadingHeaderRows = firstBodyRows.slice(
    0,
    firstNonHeaderIndex === -1 ? firstBodyRows.length : firstNonHeaderIndex,
  );
  const headerRows = [...heads.flatMap(({ rows }) => rows), ...leadingHeaderRows];
  const bodyRowCount = bodies.flatMap(({ rows }) => rows).length - leadingHeaderRows.length;

  const sortable =
    headerRows.length === 1 &&
    bodies.length === 1 &&
    bodyRowCount >= 2 &&
    bodyRowCount <= MAX_SORTABLE_ROWS &&
    !sections.flatMap(({ rows }) => rows).some(hasSpan);

  const common = { caption: table.caption, dir, tableAttributes };

  if (!sortable) {
    return { ...common, fields: [], sections };
  }

  const [headerRow] = headerRows;
  const fields = headerRow.cells.map((cell, index) => ({
    key: `col_${index}`,
    cell,
    attributes: attributesOf(cell),
  }));
  const items = firstBodyRows.slice(leadingHeaderRows.length).map((row) => ({
    ...row,
    ...Object.fromEntries(
      fields.map(({ key }, index) => [key, { text: row.cells[index]?.textContent.trim() ?? '' }]),
    ),
  }));
  const head = {
    tagName: 'thead',
    attributes: leadingHeaderRows.length ? firstBody.attributes : heads[0].attributes,
    rows: [],
  };

  return {
    ...common,
    fields,
    headerRowAttributes: headerRow.attributes,
    sections: [
      head,
      ...sections
        .filter(({ tagName }) => tagName !== 'thead')
        .map((section) => (section === firstBody ? { ...section, rows: items } : section)),
    ],
  };
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
