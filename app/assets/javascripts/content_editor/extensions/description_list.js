import { Node, mergeAttributes } from '@tiptap/core';
import { wrappingInputRule } from 'prosemirror-inputrules';

export const inputRegex = /^\s*(<dl>)$/;

export default Node.create({
  name: 'descriptionList',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  group: 'block list',
  content: 'descriptionItem+',

  parseHTML() {
    return [{ tag: 'dl' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['ul', mergeAttributes(HTMLAttributes, { class: 'dl-content' }), 0];
  },

  addInputRules() {
    return [wrappingInputRule(inputRegex, this.type)];
  },
});
