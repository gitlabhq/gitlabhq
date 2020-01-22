/* eslint-disable class-methods-use-this */

import { Node } from 'tiptap';
import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::TaskListFilter
export default class TaskList extends Node {
  get name() {
    return 'task_list';
  }

  get schema() {
    return {
      group: 'block',
      content: '(task_list_item|list_item)+',
      parseDOM: [
        {
          priority: HIGHER_PARSE_RULE_PRIORITY,
          tag: 'ul.task-list',
        },
      ],
      toDOM: () => ['ul', { class: 'task-list' }, 0],
    };
  }

  toMarkdown(state, node) {
    state.renderList(node, '  ', () => '* ');
  }
}
