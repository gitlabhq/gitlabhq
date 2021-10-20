import { Node, mergeAttributes, nodeInputRule } from '@tiptap/core';

export const inputRegex = /^<wbr>$/;

export default Node.create({
  name: 'wordBreak',
  inline: true,
  group: 'inline',
  selectable: false,
  atom: true,

  defaultOptions: {
    HTMLAttributes: {
      class: 'gl-display-inline-flex gl-px-1 gl-bg-blue-100 gl-rounded-base gl-font-sm',
    },
  },

  parseHTML() {
    return [{ tag: 'wbr' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), '-'];
  },

  addInputRules() {
    return [nodeInputRule(inputRegex, this.type)];
  },
});
