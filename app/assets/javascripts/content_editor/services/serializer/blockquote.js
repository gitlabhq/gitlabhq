import { containsEmptyParagraph, buffer, placeholder } from '../serialization_helpers';

function blockquote(state, node) {
  if (state.options.skipEmptyNodes) {
    if (!node.childCount || containsEmptyParagraph(node)) return;
  }

  const { multiline } = node.attrs;

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
    state.wrapBlock('> ', null, node, () => state.renderContent(node));
  }
}

export default blockquote;
