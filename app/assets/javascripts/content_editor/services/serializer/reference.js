import { ensureSpace } from '../serialization_helpers';

const reference = (state, node) => {
  ensureSpace(state);
  state.write(node.attrs.originalText || node.attrs.text);
};

export default reference;
