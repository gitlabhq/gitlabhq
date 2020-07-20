import { buildUneditableOpenTokens, buildUneditableCloseToken } from './build_uneditable_token';

const identifierRegex = /(^\[.+\]: .+)/;

const isIdentifier = text => {
  return identifierRegex.test(text);
};

const canRender = (node, context) => {
  return isIdentifier(context.getChildrenText(node));
};

const render = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();

export default { canRender, render };
