import { buffer, renderTagOpen, renderTagClose, renderContent } from '../serialization_helpers';

export function renderHTMLNode(tagName, forceRenderContentInline = false) {
  return (state, node) => {
    renderTagOpen(state, tagName, node.attrs);

    const buffered = buffer(state, () => renderContent(state, node, forceRenderContentInline));
    if (buffered.includes('\\') && !buffered.includes('\n')) {
      state.out += `\n\n${buffered}\n`;
    } else {
      state.out += buffered;
    }

    renderTagClose(state, tagName, false);

    if (forceRenderContentInline) {
      state.closeBlock(node);
      state.flushClose();
    }
  };
}

const htmlNode = (name) => (state, node) => renderHTMLNode(name)(state, node);

export default htmlNode;
