// Node spec helpers

export const buildMockTextNode = (literal) => ({ literal, type: 'text' });

export const normalTextNode = buildMockTextNode('This is just normal text.');

// Token spec helpers

const buildMockUneditableOpenToken = (type) => {
  return {
    type: 'openTag',
    tagName: type,
    attributes: { contenteditable: false },
    classNames: [
      'gl-px-4 gl-py-2 gl-my-5 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
    ],
  };
};

const buildMockTextToken = (content) => {
  return {
    type: 'text',
    tagName: null,
    content,
  };
};

const buildMockUneditableCloseToken = (type) => ({ type: 'closeTag', tagName: type });

export const originToken = buildMockTextToken('{:.no_toc .hidden-md .hidden-lg}');
const uneditableOpenToken = buildMockUneditableOpenToken('div');
export const uneditableOpenTokens = [uneditableOpenToken, originToken];
export const uneditableCloseToken = buildMockUneditableCloseToken('div');
export const uneditableCloseTokens = [originToken, uneditableCloseToken];
export const uneditableTokens = [...uneditableOpenTokens, uneditableCloseToken];

export const originInlineToken = {
  type: 'text',
  content: '<i>Inline</i> content',
};

export const uneditableInlineTokens = [
  buildMockUneditableOpenToken('a'),
  originInlineToken,
  buildMockUneditableCloseToken('a'),
];

export const uneditableBlockTokens = [
  uneditableOpenToken,
  buildMockTextToken('<div><h1>Some header</h1><p>Some paragraph</p></div>'),
  uneditableCloseToken,
];

export const attributeDefinition = '{:.no_toc .hidden-md .hidden-lg}';
