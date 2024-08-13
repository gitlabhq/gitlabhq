import { uniq } from 'lodash';
import { preserveUnchanged, renderTagClose, renderTagOpen } from '../serialization_helpers';

const tableMap = new WeakMap();

function getChildren(node) {
  const children = [];
  for (let i = 0; i < node.childCount; i += 1) {
    children.push(node.child(i));
  }
  return children;
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

function unsetIsInBlockTable(table) {
  tableMap.delete(table);

  const { rows, cells } = getRowsAndCells(table);
  rows.forEach((row) => tableMap.delete(row));
  cells.forEach((cell) => {
    tableMap.delete(cell);
    if (cell.childCount) tableMap.delete(cell.child(0));
  });
}

export function shouldRenderHTMLTable(table) {
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

export function isInBlockTable(node) {
  return tableMap.get(node);
}

export function isInTable(node) {
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

const table = preserveUnchanged((state, node) => {
  state.flushClose();
  setIsInBlockTable(node, shouldRenderHTMLTable(node));

  if (isInBlockTable(node)) renderTagOpen(state, 'table');

  state.renderContent(node);

  if (isInBlockTable(node)) renderTagClose(state, 'table');

  // ensure at least one blank line after any table
  state.closeBlock(node);
  state.flushClose();

  unsetIsInBlockTable(node);
});

export default table;
