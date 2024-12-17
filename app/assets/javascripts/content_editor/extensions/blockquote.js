import { Blockquote } from '@tiptap/extension-blockquote';
import { wrappingInputRule } from '@tiptap/core';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export default Blockquote.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addAttributes() {
    return {
      ...this.parent?.(),

      multiline: {
        default: false,
        parseHTML: (element) => {
          return getMarkdownSource(element)?.trim().startsWith('>>>');
        },
      },
    };
  },

  addInputRules() {
    const multilineInputRegex = /^\s*>>>\s$/gm;

    return [
      ...this.parent(),
      wrappingInputRule({
        find: multilineInputRegex,
        type: this.type,
        getAttributes: () => ({ multiline: true }),
      }),
    ];
  },
});
