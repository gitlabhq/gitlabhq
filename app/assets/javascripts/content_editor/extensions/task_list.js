import { mergeAttributes } from '@tiptap/core';
import { TaskList } from '@tiptap/extension-task-list';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export default TaskList.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: { dir: 'auto' },
    };
  },

  addAttributes() {
    return {
      numeric: {
        default: false,
        parseHTML: (element) => element.tagName.toLowerCase() === 'ol',
      },
      start: {
        default: 1,
        parseHTML: (element) =>
          element.hasAttribute('start') ? parseInt(element.getAttribute('start') || '', 10) : 1,
      },

      parens: {
        default: false,
        parseHTML: (element) => /^[0-9]+\)/.test(getMarkdownSource(element)),
      },
      bullet: {
        default: '*',
        parseHTML(element) {
          const bullet = getMarkdownSource(element)?.trim().charAt(0);
          return '*+-'.includes(bullet) ? bullet : '*';
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
      {
        tag: '.gl-new-dropdown',
        ignore: true,
      },
    ];
  },

  renderHTML({ HTMLAttributes: { numeric, ...HTMLAttributes } }) {
    return [
      numeric ? 'ol' : 'ul',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, { 'data-type': 'taskList' }),
      0,
    ];
  },
});
