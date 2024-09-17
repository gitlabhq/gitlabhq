import { renderTextInline } from '../serialization_helpers';

const referenceLabel = (state, node) => {
  renderTextInline(node.attrs.originalText || `~${state.quote(node.attrs.text)}`, state, node);
};

export default referenceLabel;
