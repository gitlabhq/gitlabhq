import { TaskItem } from '@tiptap/extension-task-item';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default TaskItem.extend({
  draggable: true,

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
        renderHTML: (attributes) => attributes.checked && { 'data-checked': true },
        keepOnSplit: false,
      },
      inapplicable: {
        default: false,
        parseHTML: (element) => {
          const checkbox = element.querySelector('input[type=checkbox].task-list-item-checkbox');

          return typeof checkbox?.dataset.inapplicable !== 'undefined';
        },
        renderHTML: (attributes) => attributes.inapplicable && { 'data-inapplicable': true },
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
      {
        tag: 'li.inapplicable > s, li.inapplicable > p:first-of-type > s',
        skip: true,
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  addNodeView() {
    const nodeView = this.parent?.();
    return ({ node, ...args }) => {
      const nodeViewInstance = nodeView({ node, ...args });

      if (node.attrs.inapplicable) {
        nodeViewInstance.dom.querySelector('input[type=checkbox]').disabled = true;
      }

      return nodeViewInstance;
    };
  },
});
