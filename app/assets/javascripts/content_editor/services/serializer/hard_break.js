import { preserveUnchanged } from '../serialization_helpers';
import { isInTable } from './table';

// eslint-disable-next-line max-params
function renderHardBreak(state, node, parent, index) {
  const br = isInTable(parent) ? '<br>' : '\\\n';

  for (let i = index + 1; i < parent.childCount; i += 1) {
    if (parent.child(i).type !== node.type) {
      state.write(br);
      return;
    }
  }
}

const hardBreak = preserveUnchanged(renderHardBreak);

export default hardBreak;
