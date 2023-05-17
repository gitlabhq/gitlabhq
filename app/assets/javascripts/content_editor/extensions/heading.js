import { Heading } from '@tiptap/extension-heading';
import { textblockTypeInputRule } from '@tiptap/core';

export default Heading.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addInputRules() {
    return this.options.levels.map((level) => {
      return textblockTypeInputRule({
        // make sure heading regex doesn't conflict with issue references
        find: new RegExp(`^(#{1,${level}})[ \t]$`),
        type: this.type,
        getAttributes: { level },
      });
    });
  },
});
