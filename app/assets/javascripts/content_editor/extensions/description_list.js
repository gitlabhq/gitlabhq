import { Node, mergeAttributes, wrappingInputRule } from '@tiptap/core';

export default Node.create({
  name: 'descriptionList',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  group: 'block list',
  content: 'descriptionItem+',

  addOptions() {
    return {
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  parseHTML() {
    return [{ tag: 'dl' }];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      'ul',
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, { class: 'dl-content' }),
      0,
    ];
  },

  addInputRules() {
    const inputRegex = /^\s*(<dl>)$/;

    return [wrappingInputRule({ find: inputRegex, type: this.type })];
  },
});
