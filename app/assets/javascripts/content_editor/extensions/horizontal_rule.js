import { nodeInputRule } from '@tiptap/core';
import { HorizontalRule } from '@tiptap/extension-horizontal-rule';

export const hrInputRuleRegExp = /^---$/;

export default HorizontalRule.extend({
  addInputRules() {
    return [nodeInputRule(hrInputRuleRegExp, this.type)];
  },
});
