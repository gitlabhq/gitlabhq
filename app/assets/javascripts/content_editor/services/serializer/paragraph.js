import { preserveUnchanged, containsOnlyText } from '../serialization_helpers';
import { renderHTMLNode } from './html_node';

const paragraph = preserveUnchanged((state, node) => {
  const { sourceMarkdown, sourceTagName } = node.attrs;
  if (sourceTagName === 'p' && !sourceMarkdown && containsOnlyText(node)) {
    renderHTMLNode(sourceTagName, true)(state, node);
    return;
  }

  state.renderInline(node);
  state.closeBlock(node);
});

export default paragraph;
