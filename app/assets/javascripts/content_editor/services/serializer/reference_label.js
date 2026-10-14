import { renderTextInline } from '../serialization_helpers';

const referenceLabel = (state, node, ...position) => {
  const [parent, index] = position;

  renderTextInline(node.attrs.originalText || `~${state.quote(node.attrs.text)}`, state, {
    node,
    parent,
    index,
  });
};

export default referenceLabel;
