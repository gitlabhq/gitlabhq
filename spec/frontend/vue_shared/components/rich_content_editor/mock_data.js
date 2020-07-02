const buildMockTextNode = literal => {
  return {
    firstChild: null,
    literal,
    type: 'text',
  };
};

const buildMockTextNodeWithAdjacentInlineCode = isForward => {
  const direction = isForward ? 'next' : 'prev';
  const literalOpen = '[';
  const literalClose = ' file]: https://file.com/file.md';
  return {
    literal: isForward ? literalOpen : literalClose,
    type: 'text',
    [direction]: {
      literal: 'raw',
      tickCount: 1,
      type: 'code',
      [direction]: {
        literal: isForward ? literalClose : literalOpen,
        [direction]: null,
      },
    },
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
export const identifierTextNode = buildMockTextNode('[Some text]: https://link.com');
export const identifierInlineCodeTextEnteringNode = buildMockTextNodeWithAdjacentInlineCode(true);
export const identifierInlineCodeTextExitingNode = buildMockTextNodeWithAdjacentInlineCode(false);
export const embeddedRubyTextNode = buildMockTextNode('<%= partial("some/path") %>');
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
export const uneditableCloseTokens = [originToken, uneditableCloseToken];
export const uneditableTokens = [...uneditableOpenTokens, uneditableCloseToken];
