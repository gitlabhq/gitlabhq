import { TableHeader } from '@tiptap/extension-table-header';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import TableCellHeaderWrapper from '../components/wrappers/table_cell_header.vue';
import { isBlockTablesFeatureEnabled } from '../services/feature_flags';

export default TableHeader.extend({
  content: isBlockTablesFeatureEnabled() ? 'block+' : 'inline*',
  addNodeView() {
    return VueNodeViewRenderer(TableCellHeaderWrapper);
  },
});
