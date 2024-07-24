import { ensureSpace } from '../serialization_helpers';

const referenceLabel = (state, node) => {
  ensureSpace(state);
  state.write(node.attrs.originalText || `~${state.quote(node.attrs.text)}`);
};

export default referenceLabel;
