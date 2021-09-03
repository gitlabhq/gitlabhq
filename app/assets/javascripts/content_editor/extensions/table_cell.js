import { TableCell } from '@tiptap/extension-table-cell';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellBodyWrapper from '../components/wrappers/table_cell_body.vue';
import { isBlockTablesFeatureEnabled } from '../services/feature_flags';

export default TableCell.extend({
  content: isBlockTablesFeatureEnabled() ? 'block+' : 'inline*',

  addNodeView() {
    return VueNodeViewRenderer(TableCellBodyWrapper);
  },
});
