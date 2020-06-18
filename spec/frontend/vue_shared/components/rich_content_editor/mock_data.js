const buildMockTextNode = literal => {
  return {
    firstChild: null,
    literal,
    type: 'text',
  };
};

const buildMockListNode = literal => {
  return {
    firstChild: {
      firstChild: {
        firstChild: buildMockTextNode(literal),
        type: 'paragraph',
      },
      type: 'item',
    },
    type: 'list',
  };
};

export const kramdownListNode = buildMockListNode('TOC');
export const normalListNode = buildMockListNode('Just another bullet point');

export const kramdownTextNode = buildMockTextNode('{:toc}');
export const normalTextNode = buildMockTextNode('This is just normal text.');

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
export const uneditableTokens = [...uneditableOpenTokens, uneditableCloseToken];
