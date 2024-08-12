import { renderHTMLNode } from './html_node';

// eslint-disable-next-line max-params
const descriptionItem = (state, node, parent, index) => {
  if (index === 1) state.ensureNewLine();
  renderHTMLNode(node.attrs.isTerm ? 'dt' : 'dd')(state, node);
  if (index === parent.childCount - 1) state.ensureNewLine();
};

export default descriptionItem;
