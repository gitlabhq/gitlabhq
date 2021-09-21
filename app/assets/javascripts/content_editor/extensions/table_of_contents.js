import { Node, nodeInputRule } from '@tiptap/core';
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
    return inputRuleRegExps.map((regex) => nodeInputRule(regex, this.type));
  },
});
