import { TaskItem } from '@tiptap/extension-task-item';
import { __, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import { getColumnHeaderText } from '../services/utils';

function getTaskItemCheckbox(element) {
  // We match the containing <li> in parseHTML below, but the <input> itself for
  // task table items (as otherwise we'd be replacing the table cell itself).
  if (element.tagName === 'INPUT') {
    return element;
  }

  return element.querySelector('input[type=checkbox].task-list-item-checkbox');
}

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
          const checkbox = getTaskItemCheckbox(element);

          return checkbox?.checked;
        },
        renderHTML: (attributes) => attributes.checked && { 'data-checked': true },
        keepOnSplit: false,
      },
      inapplicable: {
        default: false,
        parseHTML: (element) => {
          const checkbox = getTaskItemCheckbox(element);

          return typeof checkbox?.dataset.inapplicable !== 'undefined';
        },
        renderHTML: (attributes) => attributes.inapplicable && { 'data-inapplicable': true },
        keepOnSplit: false,
      },
      taskTableItem: {
        default: false,
        renderHTML: () => {},
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
        tag: 'li.inapplicable s.inapplicable',
        skip: true,
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
      {
        tag: 'td.task-table-item input[type=checkbox].task-list-item-checkbox, th.task-table-item input[type=checkbox].task-list-item-checkbox',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        attrs: {
          taskTableItem: true,
        },
      },
    ];
  },

  addNodeView() {
    const nodeView = this.parent?.();
    return ({ node, ...args }) => {
      const nodeViewInstance = nodeView({ node, ...args });
      const checkbox = nodeViewInstance.dom.querySelector('input[type=checkbox]');

      const updateAriaLabel = (target) => {
        if (target.attrs.taskTableItem) {
          if (typeof args.getPos !== 'function') return;
          const pos = args.getPos();
          const headerText = getColumnHeaderText(args.editor.state.doc, pos);
          if (!headerText) return;

          checkbox.setAttribute(
            'aria-label',
            sprintf(__('Check option in column "%{column}"'), {
              column: headerText,
            }),
          );
        } else {
          const textContent = target.firstChild?.textContent;
          if (!textContent) return;

          checkbox.setAttribute(
            'aria-label',
            sprintf(__('Check option: %{option}'), {
              option: truncate(textContent, 100),
            }),
          );
        }
      };

      updateAriaLabel(node);

      if (node.attrs.inapplicable) {
        checkbox.disabled = true;
      }

      return {
        ...nodeViewInstance,
        update: (updatedNode) => {
          const result = nodeViewInstance.update(updatedNode);
          updateAriaLabel(updatedNode);
          return result;
        },
      };
    };
  },
});
