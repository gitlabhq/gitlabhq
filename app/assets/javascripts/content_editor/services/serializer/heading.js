import { preserveUnchanged, containsOnlyText, buffer } from '../serialization_helpers';
import { renderHTMLNode } from './html_node';

const heading = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  const { sourceMarkdown, sourceTagName } = node.attrs;
  if (sourceTagName === `h${node.attrs.level}` && !sourceMarkdown && containsOnlyText(node)) {
    renderHTMLNode(sourceTagName, true)(state, node);
    return;
  }

  const setextHeadingChar = sourceMarkdown?.split('\n')[1]?.charAt(0);
  const renderHeading = () => state.renderInline(node, false);
  const isSetextHeading1 = setextHeadingChar === '=' && node.attrs.level === 1;
  const isSetextHeading2 = setextHeadingChar === '-' && node.attrs.level === 2;

  if (isSetextHeading1 || isSetextHeading2) {
    const buffered = buffer(state, () => renderHeading(), false);

    state.write(`\n${setextHeadingChar.repeat(buffered.trim().length)}`);
  } else {
    // atx headings
    state.write(`${'#'.repeat(node.attrs.level)} `);
    renderHeading();
  }

  state.closeBlock(node);
});

export default heading;
