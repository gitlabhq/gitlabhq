import { TaskItem } from '@tiptap/extension-task-item';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default TaskItem.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      nested: true,
      HTMLAttributes: { dir: 'auto' },
    };
  },

  addAttributes() {
    return {
      checked: {
        default: false,
        parseHTML: (element) => {
          const checkbox = element.querySelector('input[type=checkbox].task-list-item-checkbox');

          return checkbox?.checked;
        },
        renderHTML: (attributes) => ({
          'data-checked': attributes.checked,
        }),
        keepOnSplit: false,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'li.task-list-item',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },
});
