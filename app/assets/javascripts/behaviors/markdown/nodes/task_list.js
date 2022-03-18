import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::TaskListFilter
export default () => ({
  name: 'task_list',
  schema: {
    group: 'block',
    content: '(task_list_item|list_item)+',
    parseDOM: [
      {
        priority: HIGHER_PARSE_RULE_PRIORITY,
        tag: 'ul.task-list',
      },
    ],
    toDOM: () => ['ul', { class: 'task-list' }, 0],
  },
  toMarkdown(state, node) {
    state.renderList(node, '  ', () => '* ');
  },
});
