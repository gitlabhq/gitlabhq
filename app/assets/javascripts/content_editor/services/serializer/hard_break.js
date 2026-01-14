import { openTag } from '../serialization_helpers';
import { isInTable } from './table';

// eslint-disable-next-line max-params
function hardBreak(state, node, parent, index) {
  let br = '\\\n';

  if (isInTable(parent)) br = openTag('br');

  for (let i = index + 1; i < parent.childCount; i += 1) {
    if (parent.child(i).type !== node.type) {
      state.write(br);
      return;
    }
  }
}

export default hardBreak;
