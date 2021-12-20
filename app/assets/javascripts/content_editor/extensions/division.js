import { Node } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_LOWEST } from '../constants';

const getDiv = (element) => {
  if (element.nodeName === 'DIV') return element;
  return element.querySelector('div');
};

export default Node.create({
  name: 'division',
  content: 'block*',
  group: 'block',
  defining: true,

  addAttributes() {
    return {
      className: {
        default: null,
        parseHTML: (element) => getDiv(element).className || null,
      },
    };
  },

  parseHTML() {
    return [{ tag: 'div', priority: PARSE_HTML_PRIORITY_LOWEST }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', HTMLAttributes, 0];
  },
});
