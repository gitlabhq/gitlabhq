import { preserveUnchanged } from '../serialization_helpers';

const frontmatter = preserveUnchanged((state, node) => {
  const { language } = node.attrs;
  const syntax = {
    toml: '+++',
    json: ';;;',
    yaml: '---',
  }[language];

  state.write(`${syntax}\n`);
  state.text(node.textContent, false);
  state.ensureNewLine();
  state.write(syntax);
  state.closeBlock(node);
});

export default frontmatter;
