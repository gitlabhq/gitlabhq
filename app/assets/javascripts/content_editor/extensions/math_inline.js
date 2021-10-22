import { Mark, markInputRule } from '@tiptap/core';
import { __ } from '~/locale';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Mark.create({
  name: 'mathInline',

  parseHTML() {
    return [
      {
        tag: 'code.math[data-math-style=inline]',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      'code',
      {
        title: __('Inline math'),
        'data-toggle': 'tooltip',
        class: 'gl-inset-border-1-gray-400',
        ...HTMLAttributes,
      },
      0,
    ];
  },

  addInputRules() {
    const inputRegex = /(?:^|\s)\$`([^`]+)`\$$/gm;

    return [markInputRule({ find: inputRegex, type: this.type })];
  },
});
