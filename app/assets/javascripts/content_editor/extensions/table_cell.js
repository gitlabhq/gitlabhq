import { TableCell } from '@tiptap/extension-table-cell';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellWrapper from '../components/wrappers/table_cell.vue';
import { isBlockTablesFeatureEnabled } from '../services/feature_flags';

export default TableCell.extend({
  content: isBlockTablesFeatureEnabled() ? 'block+' : 'inline*',

  addNodeView() {
    return VueNodeViewRenderer(TableCellWrapper);
  },
});
