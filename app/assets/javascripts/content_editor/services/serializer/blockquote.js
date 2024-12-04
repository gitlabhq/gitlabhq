import {
  preserveUnchanged,
  containsEmptyParagraph,
  buffer,
  placeholder,
  setIsInBlockquote,
} from '../serialization_helpers';
import { renderHTMLNode } from './html_node';

const blockquote = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes) {
    if (!node.childCount || containsEmptyParagraph(node)) return;
  }

  const { multiline, sourceMarkdown, sourceTagName } = node.attrs;
  if (sourceTagName && !sourceMarkdown) {
    renderHTMLNode(sourceTagName)(state, node);
    return;
  }

  if (multiline) {
    const placeholderQuotes = placeholder(state);
    const bufferedContent = buffer(
      state,
      () => {
        state.write(placeholderQuotes.value);
        state.ensureNewLine();
        state.renderContent(node);
        state.ensureNewLine();
        state.write(placeholderQuotes.value);
        state.closeBlock(node);
      },
      false,
    );
    const numQuotes = Math.max(2, bufferedContent.match(/>>>+/g)?.[0]?.length || 0) + 1;

    placeholderQuotes.replaceWith('>'.repeat(numQuotes));
  } else {
    setIsInBlockquote(true);
    state.wrapBlock('> ', null, node, () => state.renderContent(node));
    setIsInBlockquote(false);
  }
});

export default blockquote;
