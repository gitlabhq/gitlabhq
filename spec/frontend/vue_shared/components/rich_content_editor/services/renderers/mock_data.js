// Node spec helpers

export const buildMockTextNode = literal => {
  return {
    firstChild: null,
    literal,
    type: 'text',
  };
};

export const normalTextNode = buildMockTextNode('This is just normal text.');

// Token spec helpers

const buildUneditableOpenToken = type => {
  return {
    type: 'openTag',
    tagName: type,
    attributes: { contenteditable: false },
    classNames: [
      'gl-px-4 gl-py-2 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
    ],
  };
};

const buildUneditableCloseToken = type => {
  return { type: 'closeTag', tagName: type };
};

export const originToken = {
  type: 'text',
  content: '{:.no_toc .hidden-md .hidden-lg}',
};
export const uneditableCloseToken = buildUneditableCloseToken('div');
export const uneditableOpenTokens = [buildUneditableOpenToken('div'), originToken];
export const uneditableCloseTokens = [originToken, uneditableCloseToken];
export const uneditableTokens = [...uneditableOpenTokens, uneditableCloseToken];

export const originInlineToken = {
  type: 'text',
  content: '<i>Inline</i> content',
};
export const uneditableInlineTokens = [
  buildUneditableOpenToken('span'),
  originInlineToken,
  buildUneditableCloseToken('span'),
];
