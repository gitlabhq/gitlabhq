import { TableHeader } from '@tiptap/extension-table-header';
import { isBlockTablesFeatureEnabled } from '../services/feature_flags';

export default TableHeader.extend({
  content: isBlockTablesFeatureEnabled() ? 'block+' : 'inline*',
});
