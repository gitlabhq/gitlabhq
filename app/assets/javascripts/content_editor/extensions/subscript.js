import { markInputRule } from '@tiptap/core';
import { Subscript } from '@tiptap/extension-subscript';
import { markInputRegex, extractMarkAttributesFromMatch } from '../services/mark_utils';

export default Subscript.extend({
  addInputRules() {
    return [markInputRule(markInputRegex('sub'), this.type, extractMarkAttributesFromMatch)];
  },
});
