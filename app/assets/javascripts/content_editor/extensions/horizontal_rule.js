import { nodeInputRule } from '@tiptap/core';
import { HorizontalRule } from '@tiptap/extension-horizontal-rule';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const hrInputRuleRegExp = /^---$/;

export const tiptapExtension = HorizontalRule.extend({
  addInputRules() {
    return [nodeInputRule(hrInputRuleRegExp, this.type)];
  },
});
export const serializer = defaultMarkdownSerializer.nodes.horizontal_rule;
