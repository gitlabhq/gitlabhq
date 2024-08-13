import { containsParagraphWithOnlyText } from '../serialization_helpers';
import { isInBlockTable } from './table';

const tableCell = (state, node) => {
  if (!isInBlockTable(node) || containsParagraphWithOnlyText(node)) {
    state.renderInline(node.child(0));
  } else {
    state.renderContent(node);
  }
};

export default tableCell;
