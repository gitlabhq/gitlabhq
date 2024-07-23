import { renderContent, renderHTMLNode } from '../serialization_helpers';

const detailsContent = (state, node, parent, index) => {
  if (!index) renderHTMLNode('summary')(state, node);
  else {
    if (index === 1) state.ensureNewLine();
    renderContent(state, node);
    if (index === parent.childCount - 1) state.ensureNewLine();
  }
};

export default detailsContent;
