import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { wrappingInputRule } from 'prosemirror-inputrules';
import DetailsWrapper from '../components/wrappers/details.vue';

export const inputRegex = /^\s*(<details>)$/;

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
    return [wrappingInputRule(inputRegex, this.type)];
  },

  addCommands() {
    return {
      setDetails: () => ({ commands }) => commands.wrapInList('details'),
      toggleDetails: () => ({ commands }) => commands.toggleList('details', 'detailsContent'),
    };
  },
});
