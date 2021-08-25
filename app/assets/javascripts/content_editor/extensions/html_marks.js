import { Mark, mergeAttributes, markInputRule } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_LOWEST } from '../constants';
import { markInputRegex, extractMarkAttributesFromMatch } from '../services/mark_utils';

const marks = [
  'ins',
  'abbr',
  'bdo',
  'cite',
  'dfn',
  'mark',
  'small',
  'span',
  'time',
  'kbd',
  'q',
  'samp',
  'var',
  'ruby',
  'rp',
  'rt',
];

const attrs = {
  time: ['datetime'],
  abbr: ['title'],
  span: ['dir'],
  bdo: ['dir'],
};

export default marks.map((name) =>
  Mark.create({
    name,

    inclusive: false,

    defaultOptions: {
      HTMLAttributes: {},
    },

    addAttributes() {
      return (attrs[name] || []).reduce(
        (acc, attr) => ({
          ...acc,
          [attr]: {
            default: null,
            parseHTML: (element) => ({ [attr]: element.getAttribute(attr) }),
          },
        }),
        {},
      );
    },

    parseHTML() {
      return [{ tag: name, priority: PARSE_HTML_PRIORITY_LOWEST }];
    },

    renderHTML({ HTMLAttributes }) {
      return [name, mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
    },

    addInputRules() {
      return [markInputRule(markInputRegex(name), this.type, extractMarkAttributesFromMatch)];
    },
  }),
);
