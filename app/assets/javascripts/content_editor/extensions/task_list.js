import { mergeAttributes } from '@tiptap/core';
import { TaskList } from '@tiptap/extension-task-list';

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
        priority: 100,
      },
    ];
  },

  renderHTML({ HTMLAttributes: { type, ...HTMLAttributes } }) {
    return [type, mergeAttributes(HTMLAttributes, { 'data-type': 'taskList' }), 0];
  },
});
