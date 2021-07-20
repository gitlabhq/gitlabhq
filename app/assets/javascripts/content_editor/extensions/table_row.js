import { TableRow } from '@tiptap/extension-table-row';

export const tiptapExtension = TableRow.extend({
  allowGapCursor: false,
});

export function serializer(state, node) {
  const isHeaderRow = node.child(0).type.name === 'tableHeader';

  const renderRow = () => {
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

    return cellWidths;
  };

  const renderHeaderRow = (cellWidths) => {
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
  };

  if (isHeaderRow) {
    renderHeaderRow(renderRow());
  } else {
    renderRow();
  }
}
