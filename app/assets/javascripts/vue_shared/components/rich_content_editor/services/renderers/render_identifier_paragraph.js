import { renderUneditableBranch as render } from './render_utils';

const identifierRegex = /(^\[.+\]: .+)/;

const isIdentifier = text => {
  return identifierRegex.test(text);
};

const canRender = (node, context) => {
  return isIdentifier(context.getChildrenText(node));
};

export default { canRender, render };
