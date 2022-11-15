import { markInputRule } from '@tiptap/core';
import { Highlight } from '@tiptap/extension-highlight';
import { markInputRegex, extractMarkAttributesFromMatch } from '../services/mark_utils';

export default Highlight.extend({
  addInputRules() {
    return [
      markInputRule({
        find: markInputRegex('mark'),
        type: this.type,
        getAttributes: extractMarkAttributesFromMatch,
      }),
    ];
  },

  addPasteRules() {
    return [];
  },
});
