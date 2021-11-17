import { TableHeader } from '@tiptap/extension-table-header';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellHeaderWrapper from '../components/wrappers/table_cell_header.vue';

export default TableHeader.extend({
  content: 'block+',
  addNodeView() {
    return VueNodeViewRenderer(TableCellHeaderWrapper);
  },
});
