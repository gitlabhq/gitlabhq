import { TableHeader } from '@tiptap/extension-table-header';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { CellSelection } from '@tiptap/pm/tables';
import TableCellHeaderWrapper from '../components/wrappers/table_cell_header.vue';

export default TableHeader.extend({
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

  addCommands() {
    return {
      ...this.parent?.(),
      alignColumn:
        (pos, align) =>
        ({ commands }) => {
          commands.selectColumn(pos);
          commands.updateAttributes('tableHeader', { align });
          commands.updateAttributes('tableCell', { align });
        },
      alignColumnLeft:
        (pos) =>
        ({ commands }) =>
          commands.alignColumn(pos, 'left'),
      alignColumnCenter:
        (pos) =>
        ({ commands }) =>
          commands.alignColumn(pos, 'center'),
      alignColumnRight:
        (pos) =>
        ({ commands }) =>
          commands.alignColumn(pos, 'right'),
      selectColumn:
        (pos) =>
        ({ tr, dispatch }) => {
          if (dispatch) {
            const position = tr.doc.resolve(pos);
            const colSelection = CellSelection.colSelection(position);
            tr.setSelection(colSelection);
          }

          return true;
        },
    };
  },

  addNodeView() {
    return VueNodeViewRenderer(TableCellHeaderWrapper);
  },
});
