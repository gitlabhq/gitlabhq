import { Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_LOWEST } from '../constants';

const tags = ['div', 'pre'];

const createHtmlNodeExtension = (tagName) =>
  Node.create({
    name: tagName,
    content: 'block*',
    group: 'block',
    defining: true,
    addOptions() {
      return {
        tagName,
      };
    },
    parseHTML() {
      return [{ tag: tagName, priority: PARSE_HTML_PRIORITY_LOWEST }];
    },
    renderHTML({ HTMLAttributes }) {
      return [tagName, HTMLAttributes, 0];
    },
  });

export default tags.map(createHtmlNodeExtension);
