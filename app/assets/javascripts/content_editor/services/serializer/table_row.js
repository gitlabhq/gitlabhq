import { omit } from 'lodash';
import {
  buffer,
  renderTagClose,
  renderTagOpen,
  containsParagraphWithOnlyText,
} from '../serialization_helpers';
import { isInBlockTable } from './table';

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
    const cellContent = buffer(state, () => state.render(cell, node, i));
    state.write(cellContent.replace(/\|/g, '\\|'));
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

    renderTagOpen(state, tag, omit(cell.attrs, 'sourceMapKey', 'sourceMarkdown'));

    const buffered = buffer(state, () => {
      if (!containsParagraphWithOnlyText(cell)) {
        state.closeBlock(node);
        state.flushClose();
      }

      state.render(cell, node, i);
      state.flushClose(1);
    });
    if (buffered.includes('\\') && !buffered.includes('\n')) {
      state.out += `\n\n${buffered}\n`;
    } else {
      state.out += buffered;
    }

    renderTagClose(state, tag);
  });

  renderTagClose(state, 'tr');
}

const tableRow = (state, node) => {
  if (isInBlockTable(node)) {
    renderTableRowAsHTML(state, node);
  } else {
    renderTableRowAsMarkdown(state, node, node.child(0).type.name === 'tableHeader');
  }
};

export default tableRow;
