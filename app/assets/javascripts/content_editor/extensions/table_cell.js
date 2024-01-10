import { TableCell } from '@tiptap/extension-table-cell';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellBodyWrapper from '../components/wrappers/table_cell_body.vue';

export default TableCell.extend({
  content: 'block+',

  addAttributes() {
    return {
      ...this.parent?.(),
      align: {
        default: 'left',
        parseHTML: (element) => element.getAttribute('align') || element.style.textAlign || 'left',
        renderHTML: () => '',
      },
    };
  },

  addNodeView() {
    return VueNodeViewRenderer(TableCellBodyWrapper);
  },
});
