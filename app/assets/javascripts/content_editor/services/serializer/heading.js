import { preserveUnchanged, containsOnlyText } from '../serialization_helpers';
import { renderHTMLNode } from './html_node';

const heading = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  const { sourceMarkdown, sourceTagName } = node.attrs;
  if (sourceTagName && !sourceMarkdown && containsOnlyText(node)) {
    renderHTMLNode(sourceTagName, true)(state, node);
    return;
  }

  state.write(`${'#'.repeat(node.attrs.level)} `);
  state.renderInline(node, false);
  state.closeBlock(node);
});

export default heading;
