import { TableHeader } from '@tiptap/extension-table-header';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { CellSelection, isInTable, selectionCell } from '@tiptap/pm/tables';
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
        (align) =>
        ({ state, tr, dispatch }) => {
          if (!isInTable(state)) return false;

          if (dispatch) {
            const { selection } = state;
            const columns =
              selection instanceof CellSelection
                ? CellSelection.colSelection(selection.$anchorCell, selection.$headCell)
                : CellSelection.colSelection(selectionCell(state));

            columns.forEachCell((cell, pos) => {
              tr.setNodeMarkup(pos, undefined, { ...cell.attrs, align });
            });
          }

          return true;
        },
      alignColumnLeft:
        () =>
        ({ commands }) =>
          commands.alignColumn('left'),
      alignColumnCenter:
        () =>
        ({ commands }) =>
          commands.alignColumn('center'),
      alignColumnRight:
        () =>
        ({ commands }) =>
          commands.alignColumn('right'),
    };
  },

  addNodeView() {
    return VueNodeViewRenderer(TableCellHeaderWrapper);
  },
});
