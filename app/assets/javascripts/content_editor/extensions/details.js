import { Node, wrappingInputRule } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import DetailsWrapper from '../components/wrappers/details.vue';

export default Node.create({
  name: 'details',
  content: 'detailsContent+',
  // eslint-disable-next-line @gitlab/require-i18n-strings
  group: 'block list',

  parseHTML() {
    return [{ tag: 'details' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['ul', HTMLAttributes, 0];
  },

  addNodeView() {
    return VueNodeViewRenderer(DetailsWrapper);
  },

  addInputRules() {
    const inputRegex = /^\s*(<details>)$/;

    return [wrappingInputRule({ find: inputRegex, type: this.type })];
  },

  addCommands() {
    return {
      setDetails:
        () =>
        ({ commands }) =>
          commands.wrapInList('details'),
      toggleDetails:
        () =>
        ({ commands }) =>
          commands.toggleList('details', 'detailsContent'),
    };
  },
});
