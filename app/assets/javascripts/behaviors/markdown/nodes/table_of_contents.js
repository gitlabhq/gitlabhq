import { __ } from '~/locale';
import { HIGHER_PARSE_RULE_PRIORITY } from '../constants';

// Transforms generated HTML back to GFM for Banzai::Filter::TableOfContentsFilter
export default () => ({
  name: 'table_of_contents',
  schema: {
    group: 'block',
    atom: true,
    parseDOM: [
      {
        tag: 'ul.section-nav',
        priority: HIGHER_PARSE_RULE_PRIORITY,
      },
      {
        tag: 'p.table-of-contents',
        priority: HIGHER_PARSE_RULE_PRIORITY,
      },
    ],
    toDOM: () => ['p', { class: 'table-of-contents' }, __('Table of Contents')],
  },
  toMarkdown: (state, node) => {
    state.write('[[_TOC_]]');
    state.closeBlock(node);
  },
});
