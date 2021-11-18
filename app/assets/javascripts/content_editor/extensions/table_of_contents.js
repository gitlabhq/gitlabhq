import { Node, InputRule } from '@tiptap/core';
import { s__ } from '~/locale';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

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
          'table-of-contents gl-border-1 gl-border-solid gl-text-center gl-border-gray-100 gl-mb-5',
      },
      s__('ContentEditor|Table of Contents'),
    ];
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
