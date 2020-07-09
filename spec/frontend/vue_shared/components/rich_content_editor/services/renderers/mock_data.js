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

const uneditableOpenToken = {
  type: 'openTag',
  tagName: 'div',
  attributes: { contenteditable: false },
  classNames: [
    'gl-px-4 gl-py-2 gl-opacity-5 gl-bg-gray-100 gl-user-select-none gl-cursor-not-allowed',
  ],
};

export const uneditableCloseToken = { type: 'closeTag', tagName: 'div' };
export const originToken = {
  type: 'text',
  content: '{:.no_toc .hidden-md .hidden-lg}',
};
export const uneditableOpenTokens = [uneditableOpenToken, originToken];
export const uneditableCloseTokens = [originToken, uneditableCloseToken];
export const uneditableTokens = [...uneditableOpenTokens, uneditableCloseToken];
