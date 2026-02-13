import { flatten } from 'lodash';
import { renderTagClose, renderTagOpen, tableCellAsTaskTableItem } from '../serialization_helpers';

const tableMap = new WeakMap();

function getChildren(node) {
  const children = [];
  for (let i = 0; i < node.childCount; i += 1) {
    children.push(node.child(i));
  }
  return children;
}

function getRowsAndCells(t) {
  const cells = [];
  const rows = [];
  t.descendants((n) => {
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

function unsetIsInBlockTable(t) {
  tableMap.delete(t);

  const { rows, cells } = getRowsAndCells(t);
  rows.forEach((row) => tableMap.delete(row));
  cells.forEach((cell) => {
    tableMap.delete(cell);
    if (cell.childCount) tableMap.delete(cell.child(0));
  });
}

function cellsOkayForMarkdown(cells, validCellType) {
  return cells.every((cell) => {
    if (cell.type.name !== validCellType || cell.childCount !== 1) {
      return false;
    }

    const child = cell.child(0);
    if (child.type.name === 'paragraph') {
      return true;
    }

    return Boolean(tableCellAsTaskTableItem(cell));
  });
}

export function shouldRenderHTMLTable(t) {
  const { rows, cells } = getRowsAndCells(t);

  const maxColspan = Math.max(...cells.map((cell) => cell.attrs.colspan));
  const maxRowspan = Math.max(...cells.map((cell) => cell.attrs.rowspan));

  if (maxColspan !== 1 || maxRowspan !== 1) {
    // We can't represent colspan/rowspan in Markdown tables, so we must render this as HTML.
    return true;
  }

  const rowChildren = rows.map((row) => getChildren(row));
  const cellsInFirstRow = rowChildren[0];
  const cellsInOtherRows = flatten(rowChildren.slice(1));

  // To render as a Markdown table, all cells must only contain either:
  //
  // (a) a single paragraph, or
  // (b) a task list, containing a single task item, with no children.
  //
  // Additionally, the first row must only contain TableHeaders as the cell type,
  // and remaining rows must contain only TableCells.
  return (
    !cellsOkayForMarkdown(cellsInFirstRow, 'tableHeader') ||
    !cellsOkayForMarkdown(cellsInOtherRows, 'tableCell')
  );
}

export function isInBlockTable(node) {
  return tableMap.get(node);
}

export function isInTable(node) {
  return tableMap.has(node);
}

function setIsInBlockTable(t, value) {
  tableMap.set(t, value);

  const { rows, cells } = getRowsAndCells(t);
  rows.forEach((row) => tableMap.set(row, value));
  cells.forEach((cell) => {
    tableMap.set(cell, value);
    if (cell.childCount && cell.child(0).type.name === 'paragraph')
      tableMap.set(cell.child(0), value);
  });
}

function table(state, node) {
  state.flushClose();
  setIsInBlockTable(node, shouldRenderHTMLTable(node));

  if (isInBlockTable(node)) renderTagOpen(state, 'table');

  state.renderContent(node);

  if (isInBlockTable(node)) renderTagClose(state, 'table');

  // ensure at least one blank line after any table
  state.closeBlock(node);
  state.flushClose();

  unsetIsInBlockTable(node);
}

export default table;
