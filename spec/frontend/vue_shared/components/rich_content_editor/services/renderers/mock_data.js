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

const buildMockUneditableOpenToken = type => {
  return {
    type: 'openTag',
    tagName: type,
    attributes: { contenteditable: false },
    classNames: [
      'gl-px-4 gl-py-2 gl-my-5 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
    ],
  };
};

const buildMockUneditableCloseToken = type => {
  return { type: 'closeTag', tagName: type };
};

export const originToken = {
  type: 'text',
  tagName: null,
  content: '{:.no_toc .hidden-md .hidden-lg}',
};
export const uneditableCloseToken = buildMockUneditableCloseToken('div');
export const uneditableOpenTokens = [buildMockUneditableOpenToken('div'), originToken];
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
  buildMockUneditableOpenToken('div'),
  {
    type: 'text',
    tagName: null,
    content: '<div><h1>Some header</h1><p>Some paragraph</p></div>',
  },
  buildMockUneditableCloseToken('div'),
];
