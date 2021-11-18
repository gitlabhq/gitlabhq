import { Mark, markInputRule, mergeAttributes } from '@tiptap/core';

export default Mark.create({
  name: 'inlineDiff',

  addOptions() {
    return {
      HTMLAttributes: {},
    };
  },

  addAttributes() {
    return {
      type: {
        default: 'addition',
        parseHTML: (element) => (element.classList.contains('deletion') ? 'deletion' : 'addition'),
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
    const inputRegexAddition = /(\{\+(.+?)\+\})$/gm;
    const inputRegexDeletion = /(\{-(.+?)-\})$/gm;

    return [
      markInputRule({
        find: inputRegexAddition,
        type: this.type,
        getAttributes: () => ({ type: 'addition' }),
      }),
      markInputRule({
        find: inputRegexDeletion,
        type: this.type,
        getAttributes: () => ({ type: 'deletion' }),
      }),
    ];
  },
});
