import { nodeInputRule } from '@tiptap/core';
import { HorizontalRule } from '@tiptap/extension-horizontal-rule';

export default HorizontalRule.extend({
  addInputRules() {
    const hrInputRuleRegExp = /^---$/;

    return [nodeInputRule({ find: hrInputRuleRegExp, type: this.type })];
  },
});
