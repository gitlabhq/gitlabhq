import { preserveUnchanged } from '../serialization_helpers';

const blockquote = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes) {
    if (!node.childCount) return;
    if (node.childCount === 1) {
      const child = node.child(0);
      if (child.type.name === 'paragraph' && !child.childCount) return;
    }
  }

  if (node.attrs.multiline) {
    state.write('>>>');
    state.ensureNewLine();
    state.renderContent(node);
    state.ensureNewLine();
    state.write('>>>');
    state.closeBlock(node);
  } else {
    state.wrapBlock('> ', null, node, () => state.renderContent(node));
  }
});

export default blockquote;
