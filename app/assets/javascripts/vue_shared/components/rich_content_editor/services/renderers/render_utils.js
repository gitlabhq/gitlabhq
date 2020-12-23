import {
  buildUneditableBlockTokens,
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
} from './build_uneditable_token';

export const renderUneditableLeaf = (_, { origin }) => buildUneditableBlockTokens(origin());

export const renderUneditableBranch = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();

const attributeDefinitionRegexp = /(^{:.+}$)/;

export const isAttributeDefinition = (text) => attributeDefinitionRegexp.test(text);

const findAttributeDefinition = (node) => {
  const literal =
    node?.next?.firstChild?.literal || node?.firstChild?.firstChild?.next?.next?.literal; // for headings // for list items;

  return isAttributeDefinition(literal) ? literal : null;
};

export const renderWithAttributeDefinitions = (node, { origin }) => {
  const attributes = findAttributeDefinition(node);
  const token = origin();

  if (token.type === 'openTag' && attributes) {
    Object.assign(token, {
      attributes: {
        'data-attribute-definition': attributes,
      },
    });
  }

  return token;
};

export const willAlwaysRender = () => true;
