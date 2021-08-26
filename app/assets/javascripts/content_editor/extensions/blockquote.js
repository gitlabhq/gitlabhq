import { Blockquote } from '@tiptap/extension-blockquote';
import { wrappingInputRule } from 'prosemirror-inputrules';
import { getParents } from '~/lib/utils/dom_utils';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export const multilineInputRegex = /^\s*>>>\s$/gm;

export default Blockquote.extend({
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

          return {
            multiline: source && !source.startsWith('>') && !parentsIncludeBlockquote,
          };
        },
      },
    };
  },

  addInputRules() {
    return [
      ...this.parent?.(),
      wrappingInputRule(multilineInputRegex, this.type, () => ({ multiline: true })),
    ];
  },
});
