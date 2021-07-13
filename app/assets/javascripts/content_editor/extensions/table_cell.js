import { TableCell } from '@tiptap/extension-table-cell';

export const tiptapExtension = TableCell.extend({
  content: 'inline*',
});

export function serializer(state, node) {
  state.renderInline(node);
}
