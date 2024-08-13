import { preserveUnchanged } from '../serialization_helpers';

const horizontalRule = preserveUnchanged((state, node) => {
  state.write(node.attrs.markup || '---');
  state.closeBlock(node);
});

export default horizontalRule;
