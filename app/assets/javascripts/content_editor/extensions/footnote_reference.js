import { Node, mergeAttributes } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'footnoteReference',

  inline: true,

  group: 'inline',

  atom: true,

  draggable: true,

  selectable: true,

  addAttributes() {
    return {
      footnoteId: {
        default: null,
        parseHTML: (element) => element.querySelector('a').getAttribute('id'),
      },
      footnoteNumber: {
        default: null,
        parseHTML: (element) => element.textContent,
      },
    };
  },

  parseHTML() {
    return [{ tag: 'sup.footnote-ref', priority: PARSE_HTML_PRIORITY_HIGHEST }];
  },

  renderHTML({ HTMLAttributes: { footnoteNumber, footnoteId, ...HTMLAttributes } }) {
    return ['sup', mergeAttributes(HTMLAttributes), footnoteNumber];
  },
});
