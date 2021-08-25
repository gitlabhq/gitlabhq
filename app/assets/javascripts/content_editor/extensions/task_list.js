import { mergeAttributes } from '@tiptap/core';
import { TaskList } from '@tiptap/extension-task-list';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default TaskList.extend({
  addAttributes() {
    return {
      type: {
        default: 'ul',
        parseHTML: (element) => {
          return {
            type: element.tagName.toLowerCase() === 'ol' ? 'ol' : 'ul',
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: '.task-list',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML({ HTMLAttributes: { type, ...HTMLAttributes } }) {
    return [type, mergeAttributes(HTMLAttributes, { 'data-type': 'taskList' }), 0];
  },
});
