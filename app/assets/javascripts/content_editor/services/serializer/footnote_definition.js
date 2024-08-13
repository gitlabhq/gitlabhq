import { preserveUnchanged } from '../serialization_helpers';

const footnoteDefinition = preserveUnchanged((state, node) => {
  state.write(`[^${node.attrs.identifier}]: `);
  state.renderInline(node);
  state.ensureNewLine();
});

export default footnoteDefinition;
