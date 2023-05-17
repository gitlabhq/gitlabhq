import { Blockquote } from '@tiptap/extension-blockquote';
import { wrappingInputRule } from '@tiptap/core';
import { getParents } from '~/lib/utils/dom_utils';
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
          const source = getMarkdownSource(element);
          const parentsIncludeBlockquote = getParents(element).some(
            (p) => p.nodeName.toLowerCase() === 'blockquote',
          );

          return source && !source.startsWith('>') && !parentsIncludeBlockquote;
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
