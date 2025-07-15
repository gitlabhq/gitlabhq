import { TaskItem } from '@tiptap/extension-task-item';
import { __, sprintf } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
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
      const checkbox = nodeViewInstance.dom.querySelector('input[type=checkbox]');

      const updateAriaLabel = (textContent) => {
        checkbox.setAttribute(
          'aria-label',
          sprintf(__('Check option: %{option}'), {
            option: truncate(textContent, 100),
          }),
        );
      };

      updateAriaLabel(node.firstChild.textContent);

      if (node.attrs.inapplicable) {
        checkbox.disabled = true;
      }

      return {
        ...nodeViewInstance,
        update: (updatedNode) => {
          const result = nodeViewInstance.update(updatedNode);
          updateAriaLabel(updatedNode.firstChild.textContent);
          return result;
        },
      };
    };
  },
});
