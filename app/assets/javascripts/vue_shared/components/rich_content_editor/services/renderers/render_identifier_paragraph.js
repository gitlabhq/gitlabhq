const identifierRegex = /(^\[.+\]: .+)/;

const isIdentifier = (text) => {
  return identifierRegex.test(text);
};

const canRender = (node, context) => {
  return isIdentifier(context.getChildrenText(node));
};

const getReferenceDefinitions = (node, definitions = '') => {
  if (!node) {
    return definitions;
  }

  const definition = node.type === 'text' ? node.literal : '\n';

  return getReferenceDefinitions(node.next, `${definitions}${definition}`);
};

const render = (node, { skipChildren }) => {
  const content = getReferenceDefinitions(node.firstChild);

  skipChildren();

  return [
    {
      type: 'openTag',
      tagName: 'pre',
      classNames: ['code-block', 'language-markdown'],
      attributes: { 'data-sse-reference-definition': true },
    },
    { type: 'openTag', tagName: 'code' },
    { type: 'text', content },
    { type: 'closeTag', tagName: 'code' },
    { type: 'closeTag', tagName: 'pre' },
  ];
};

export default { canRender, render };
