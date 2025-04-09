import { preserveUnchanged } from '../serialization_helpers';

const paragraph = preserveUnchanged((state, node) => {
  state.renderInline(node);
  state.closeBlock(node);
});

export default paragraph;
