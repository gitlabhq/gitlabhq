import { TableCell } from '@tiptap/extension-table-cell';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellBodyWrapper from '../components/wrappers/table_cell_body.vue';

export default TableCell.extend({
  content: 'block+',

  addNodeView() {
    return VueNodeViewRenderer(TableCellBodyWrapper);
  },
});
