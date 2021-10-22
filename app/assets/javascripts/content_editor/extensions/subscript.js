import { markInputRule } from '@tiptap/core';
import { Subscript } from '@tiptap/extension-subscript';
import { markInputRegex, extractMarkAttributesFromMatch } from '../services/mark_utils';

export default Subscript.extend({
  addInputRules() {
    return [
      markInputRule({
        find: markInputRegex('sub'),
        type: this.type,
        getAttributes: extractMarkAttributesFromMatch,
      }),
    ];
  },
});
