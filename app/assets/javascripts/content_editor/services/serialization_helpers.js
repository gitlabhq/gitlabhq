import { uniq } from 'lodash';
import { isBlockTablesFeatureEnabled } from './feature_flags';

const defaultAttrs = {
  td: { colspan: 1, rowspan: 1, colwidth: null },
  th: { colspan: 1, rowspan: 1, colwidth: null },
};

const tableMap = new WeakMap();

function shouldRenderCellInline(cell) {
  if (cell.childCount === 1) {
    const parent = cell.child(0);
    if (parent.type.name === 'paragraph' && parent.childCount === 1) {
      const child = parent.child(0);
      return child.isText && child.marks.length === 0;
    }
  }

  return false;
}

function getRowsAndCells(table) {
  const cells = [];
  const rows = [];
  table.descendants((n) => {
    if (n.type.name === 'tableCell' || n.type.name === 'tableHeader') {
      cells.push(n);
      return false;
    }

    if (n.type.name === 'tableRow') {
      rows.push(n);
    }

    return true;
  });
  return { rows, cells };
}

function getChildren(node) {
  const children = [];
  for (let i = 0; i < node.childCount; i += 1) {
    children.push(node.child(i));
  }
  return children;
}

function shouldRenderHTMLTable(table) {
  const { rows, cells } = getRowsAndCells(table);

  const cellChildCount = Math.max(...cells.map((cell) => cell.childCount));
  const maxColspan = Math.max(...cells.map((cell) => cell.attrs.colspan));
  const maxRowspan = Math.max(...cells.map((cell) => cell.attrs.rowspan));

  const rowChildren = rows.map((row) => uniq(getChildren(row).map((cell) => cell.type.name)));
  const cellTypeInFirstRow = rowChildren[0];
  const cellTypesInOtherRows = uniq(rowChildren.slice(1).map(([type]) => type));

  // if the first row has headers, and there are no headers anywhere else, render markdown table
  if (
    !(
      cellTypeInFirstRow.length === 1 &&
      cellTypeInFirstRow[0] === 'tableHeader' &&
      cellTypesInOtherRows.length === 1 &&
      cellTypesInOtherRows[0] === 'tableCell'
    )
  ) {
    return true;
  }

  if (cellChildCount === 1 && maxColspan === 1 && maxRowspan === 1) {
    // if all rows contain only one paragraph each and no rowspan/colspan, render markdown table
    const children = uniq(cells.map((cell) => cell.child(0).type.name));
    if (children.length === 1 && children[0] === 'paragraph') {
      return false;
    }
  }

  return true;
}

function openTag(state, tagName, attrs) {
  let str = `<${tagName}`;

  str += Object.entries(attrs || {})
    .map(([key, value]) => {
      if (defaultAttrs[tagName]?.[key] === value) return '';

      return ` ${key}=${state.quote(value?.toString() || '')}`;
    })
    .join('');

  return `${str}>`;
}

function closeTag(state, tagName) {
  return `</${tagName}>`;
}

function isInBlockTable(node) {
  return tableMap.get(node);
}

function isInTable(node) {
  return tableMap.has(node);
}

function setIsInBlockTable(table, value) {
  tableMap.set(table, value);

  const { rows, cells } = getRowsAndCells(table);
  rows.forEach((row) => tableMap.set(row, value));
  cells.forEach((cell) => {
    tableMap.set(cell, value);
    if (cell.childCount && cell.child(0).type.name === 'paragraph')
      tableMap.set(cell.child(0), value);
  });
}

function unsetIsInBlockTable(table) {
  tableMap.delete(table);

  const { rows, cells } = getRowsAndCells(table);
  rows.forEach((row) => tableMap.delete(row));
  cells.forEach((cell) => {
    tableMap.delete(cell);
    if (cell.childCount) tableMap.delete(cell.child(0));
  });
}

function renderTagOpen(state, tagName, attrs) {
  state.ensureNewLine();
  state.write(openTag(state, tagName, attrs));
}

function renderTagClose(state, tagName, insertNewline = true) {
  state.write(closeTag(state, tagName));
  if (insertNewline) state.ensureNewLine();
}

function renderTableHeaderRowAsMarkdown(state, node, cellWidths) {
  state.flushClose(1);

  state.write('|');
  node.forEach((cell, _, i) => {
    if (i) state.write('|');

    state.write(cell.attrs.align === 'center' ? ':' : '-');
    state.write(state.repeat('-', cellWidths[i]));
    state.write(cell.attrs.align === 'center' || cell.attrs.align === 'right' ? ':' : '-');
  });
  state.write('|');

  state.closeBlock(node);
}

function renderTableRowAsMarkdown(state, node, isHeaderRow = false) {
  const cellWidths = [];

  state.flushClose(1);

  state.write('| ');
  node.forEach((cell, _, i) => {
    if (i) state.write(' | ');

    const { length } = state.out;
    state.render(cell, node, i);
    cellWidths.push(state.out.length - length);
  });
  state.write(' |');

  state.closeBlock(node);

  if (isHeaderRow) renderTableHeaderRowAsMarkdown(state, node, cellWidths);
}

function renderTableRowAsHTML(state, node) {
  renderTagOpen(state, 'tr');

  node.forEach((cell, _, i) => {
    const tag = cell.type.name === 'tableHeader' ? 'th' : 'td';

    renderTagOpen(state, tag, cell.attrs);

    if (!shouldRenderCellInline(cell)) {
      state.closeBlock(node);
      state.flushClose();
    }

    state.render(cell, node, i);
    state.flushClose(1);

    renderTagClose(state, tag);
  });

  renderTagClose(state, 'tr');
}

export function renderTableCell(state, node) {
  if (!isBlockTablesFeatureEnabled()) {
    state.renderInline(node);
    return;
  }

  if (!isInBlockTable(node) || shouldRenderCellInline(node)) {
    state.renderInline(node.child(0));
  } else {
    state.renderContent(node);
  }
}

export function renderTableRow(state, node) {
  if (isInBlockTable(node)) {
    renderTableRowAsHTML(state, node);
  } else {
    renderTableRowAsMarkdown(state, node, node.child(0).type.name === 'tableHeader');
  }
}

export function renderTable(state, node) {
  if (isBlockTablesFeatureEnabled()) {
    setIsInBlockTable(node, shouldRenderHTMLTable(node));
  }

  if (isInBlockTable(node)) renderTagOpen(state, 'table');

  state.renderContent(node);

  if (isInBlockTable(node)) renderTagClose(state, 'table');

  // ensure at least one blank line after any table
  state.closeBlock(node);
  state.flushClose();

  if (isBlockTablesFeatureEnabled()) {
    unsetIsInBlockTable(node);
  }
}

export function renderHardBreak(state, node, parent, index) {
  const br = isInTable(parent) ? '<br>' : '\\\n';

  for (let i = index + 1; i < parent.childCount; i += 1) {
    if (parent.child(i).type !== node.type) {
      state.write(br);
      return;
    }
  }
}
