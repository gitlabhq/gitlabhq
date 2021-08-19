import { TableCell } from '@tiptap/extension-table-cell';
import { isBlockTablesFeatureEnabled } from '../services/feature_flags';

export default TableCell.extend({
  content: isBlockTablesFeatureEnabled() ? 'block+' : 'inline*',
});
