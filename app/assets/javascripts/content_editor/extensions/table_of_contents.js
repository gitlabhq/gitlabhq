import { Node, InputRule } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { __ } from '~/locale';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import TableOfContentsWrapper from '../components/wrappers/table_of_contents.vue';

export default Node.create({
  name: 'tableOfContents',

  inline: false,

  group: 'block',

  parseHTML() {
    return [
      {
        tag: 'ul.section-nav',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML() {
    return [
      'div',
      {
        class:
          'table-of-contents gl-border-1 gl-border-solid gl-text-center gl-border-default gl-mb-5',
      },
      __('Table of contents'),
    ];
  },
  addNodeView() {
    return VueNodeViewRenderer(TableOfContentsWrapper);
  },

  addCommands() {
    return {
      insertTableOfContents:
        () =>
        ({ commands }) =>
          commands.insertContent({ type: this.name }),
    };
  },

  addInputRules() {
    const { type } = this;
    const inputRuleRegExps = [/^\[\[_TOC_\]\]$/, /^\[TOC\]$/];

    return inputRuleRegExps.map(
      (regex) =>
        new InputRule({
          find: regex,
          handler: ({ state, range: { from, to }, match }) => {
            const { tr } = state;

            if (match) {
              tr.replaceWith(from - 1, to, type.create());
            }

            return tr;
          },
        }),
    );
  },
});
