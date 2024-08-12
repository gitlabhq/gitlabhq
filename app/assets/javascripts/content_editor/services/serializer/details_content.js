import { renderContent } from '../serialization_helpers';
import { renderHTMLNode } from './html_node';

// eslint-disable-next-line max-params
const detailsContent = (state, node, parent, index) => {
  if (!index) renderHTMLNode('summary')(state, node);
  else {
    if (index === 1) state.ensureNewLine();
    renderContent(state, node);
    if (index === parent.childCount - 1) state.ensureNewLine();
  }
};

export default detailsContent;
