import { Table } from '@tiptap/extension-table';

export const tiptapExtension = Table;

export function serializer(state, node) {
  state.renderContent(node);
}
