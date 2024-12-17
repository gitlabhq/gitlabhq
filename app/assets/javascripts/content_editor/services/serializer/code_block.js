import { repeatCodeBackticks } from '~/lib/utils/text_markdown';
import { preserveUnchanged } from '../serialization_helpers';

const codeBlock = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  let { language } = node.attrs;
  if (language === 'plaintext') language = '';

  const backticks = repeatCodeBackticks(node.textContent);
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
