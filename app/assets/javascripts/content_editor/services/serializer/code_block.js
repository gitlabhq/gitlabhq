import { preserveUnchanged } from '../serialization_helpers';

const codeBlock = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  let { language } = node.attrs;
  if (language === 'plaintext') language = '';

  const numBackticks = Math.max(2, node.textContent.match(/```+/g)?.[0]?.length || 0) + 1;
  const backticks = state.repeat('`', numBackticks);
  state.write(
    `${backticks}${
      (language || '') + (node.attrs.langParams ? `:${node.attrs.langParams}` : '')
    }\n`,
  );
  state.text(node.textContent, false);
  state.ensureNewLine();
  state.write(backticks);
  state.closeBlock(node);
});

export default codeBlock;
