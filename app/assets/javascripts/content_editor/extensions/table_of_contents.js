import { Node } from '@tiptap/core';
import { InputRule } from 'prosemirror-inputrules';
import { s__ } from '~/locale';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export const inputRuleRegExps = [/^\[\[_TOC_\]\]$/, /^\[TOC\]$/];

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

    return inputRuleRegExps.map(
      (regex) =>
        new InputRule(regex, (state, match, start, end) => {
          const { tr } = state;

          if (match) {
            tr.replaceWith(start - 1, end, type.create());
          }

          return tr;
        }),
    );
  },
});
