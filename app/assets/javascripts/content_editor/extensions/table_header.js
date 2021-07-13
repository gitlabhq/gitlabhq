import { TableHeader } from '@tiptap/extension-table-header';

export const tiptapExtension = TableHeader.extend({
  content: 'inline*',
});

export function serializer(state, node) {
  state.renderInline(node);
}
