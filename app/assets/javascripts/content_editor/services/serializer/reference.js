import { renderTextInline } from '../serialization_helpers';

const reference = (state, node) => {
  renderTextInline(node.attrs.originalText || node.attrs.text, state, node);
};

export default reference;
