import { Node, mergeAttributes, nodeInputRule } from '@tiptap/core';

export default Node.create({
  name: 'wordBreak',
  inline: true,
  group: 'inline',
  selectable: false,
  atom: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'gl-inline-flex gl-px-1 gl-bg-blue-100 gl-rounded-base gl-text-sm',
      },
    };
  },

  parseHTML() {
    return [{ tag: 'wbr' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), '-'];
  },

  addInputRules() {
    const inputRegex = /<wbr>$/;

    return [nodeInputRule({ find: inputRegex, type: this.type })];
  },
});
