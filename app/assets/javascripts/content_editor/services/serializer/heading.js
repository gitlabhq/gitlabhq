import { preserveUnchanged } from '../serialization_helpers';

const heading = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  state.write(`${'#'.repeat(node.attrs.level)} `);
  state.renderInline(node, false);
  state.closeBlock(node);
});

export default heading;
