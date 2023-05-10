import { Node, mergeAttributes } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const extractFootnoteIdentifier = (element) =>
  /^fnref-(\w+)-\d+$/.exec(element.querySelector('a')?.getAttribute('id'))?.[1];

export default Node.create({
  name: 'footnoteReference',

  inline: true,

  group: 'inline',

  atom: true,

  draggable: true,

  selectable: true,

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addAttributes() {
    return {
      identifier: {
        default: null,
        parseHTML: extractFootnoteIdentifier,
      },
      label: {
        default: null,
        parseHTML: extractFootnoteIdentifier,
      },
    };
  },

  parseHTML() {
    return [{ tag: 'sup.footnote-ref', priority: PARSE_HTML_PRIORITY_HIGHEST }];
  },

  renderHTML({ HTMLAttributes: { label, ...HTMLAttributes } }) {
    return ['sup', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), label];
  },
});
