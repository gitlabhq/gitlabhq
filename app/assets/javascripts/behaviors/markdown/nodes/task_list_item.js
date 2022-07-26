import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::TaskListFilter
export default () => ({
  name: 'task_list_item',
  schema: {
    attrs: {
      state: {
        default: null,
      },
    },
    defining: true,
    draggable: false,
    content: 'paragraph block*',
    parseDOM: [
      {
        priority: HIGHER_PARSE_RULE_PRIORITY,
        tag: 'li.task-list-item',
        getAttrs: (el) => {
          const checkbox = el.querySelector('input[type=checkbox].task-list-item-checkbox');
          if (checkbox?.matches('[data-inapplicable]')) {
            return { state: 'inapplicable' };
          } else if (checkbox?.checked) {
            return { state: 'done' };
          }

          return {};
        },
      },
    ],
    toDOM(node) {
      return [
        'li',
        {
          class: () => {
            if (node.attrs.state === 'inapplicable') {
              return 'task-list-item inapplicable';
            }

            return 'task-list-item';
          },
        },
        [
          'input',
          {
            type: 'checkbox',
            class: 'task-list-item-checkbox',
            checked: node.attrs.state === 'done',
            'data-inapplicable': node.attrs.state === 'inapplicable',
          },
        ],
        ['div', { class: 'todo-content' }, 0],
      ];
    },
  },
  toMarkdown(state, node) {
    switch (node.attrs.state) {
      case 'done':
        state.write('[x] ');
        break;
      case 'inapplicable':
        state.write('[~] ');
        break;
      default:
        state.write('[ ] ');
        break;
    }
    state.renderContent(node);
  },
});
