import { openTag } from '../serialization_helpers';
import { isInTable } from './table';

// eslint-disable-next-line max-params
function renderHardBreak(state, node, parent, index) {
  let br = '\\\n';
  const { sourceMarkdown, sourceTagName } = node.attrs;

  if (typeof sourceMarkdown === 'string') br = sourceMarkdown.includes('\\') ? '\\\n' : '  \n';
  else if (isInTable(parent) || sourceTagName) br = openTag('br');

  for (let i = index + 1; i < parent.childCount; i += 1) {
    if (parent.child(i).type !== node.type) {
      state.write(br);
      return;
    }
  }
}

const hardBreak = renderHardBreak;

export default hardBreak;
