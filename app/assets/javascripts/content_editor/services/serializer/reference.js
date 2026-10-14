import { renderTextInline } from '../serialization_helpers';

const reference = (state, node, ...position) => {
  const [parent, index] = position;

  renderTextInline(node.attrs.originalText || node.attrs.text, state, { node, parent, index });
};

export default reference;
