import { Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_LOWEST } from '../constants';

export default Node.create({
  name: 'division',
  content: 'block*',
  group: 'block',
  defining: true,

  parseHTML() {
    return [{ tag: 'div', priority: PARSE_HTML_PRIORITY_LOWEST }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', HTMLAttributes, 0];
  },
});
