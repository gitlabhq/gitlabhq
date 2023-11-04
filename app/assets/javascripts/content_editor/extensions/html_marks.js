import { Mark, mergeAttributes, markInputRule } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_LOWEST } from '../constants';
import { markInputRegex, extractMarkAttributesFromMatch } from '../services/mark_utils';

const marks = [
  'ins',
  'abbr',
  'bdo',
  'cite',
  'dfn',
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
    addOptions() {
      return {
        HTMLAttributes: {},
      };
    },
    addAttributes() {
      return (attrs[name] || []).reduce(
        (acc, attr) => ({
          ...acc,
          [attr]: {
            default: null,
            parseHTML: (element) => element.getAttribute(attr),
          },
        }),
        {},
      );
    },

    parseHTML() {
      const tag = name === 'span' ? `${name}:not([data-escaped-char])` : name;
      return [{ tag, priority: PARSE_HTML_PRIORITY_LOWEST }];
    },

    renderHTML({ HTMLAttributes }) {
      return [name, mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
    },

    addInputRules() {
      return [
        markInputRule({
          find: markInputRegex(name),
          type: this.type,
          getAttributes: extractMarkAttributesFromMatch,
        }),
      ];
    },
  }),
);
