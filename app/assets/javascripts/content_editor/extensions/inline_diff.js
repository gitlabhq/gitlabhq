import { Mark, markInputRule, mergeAttributes } from '@tiptap/core';

export const inputRegexAddition = /(\{\+(.+?)\+\})$/gm;
export const inputRegexDeletion = /(\{-(.+?)-\})$/gm;

export default Mark.create({
  name: 'inlineDiff',

  defaultOptions: {
    HTMLAttributes: {},
  },

  addAttributes() {
    return {
      type: {
        default: 'addition',
        parseHTML: (element) => {
          return {
            type: element.classList.contains('deletion') ? 'deletion' : 'addition',
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'span.idiff',
      },
    ];
  },

  renderHTML({ HTMLAttributes: { type, ...HTMLAttributes } }) {
    return [
      'span',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, {
        class: `idiff left right ${type}`,
      }),
      0,
    ];
  },

  addInputRules() {
    return [
      markInputRule(inputRegexAddition, this.type, () => ({ type: 'addition' })),
      markInputRule(inputRegexDeletion, this.type, () => ({ type: 'deletion' })),
    ];
  },
});
