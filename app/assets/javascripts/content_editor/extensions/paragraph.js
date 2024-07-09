import Paragraph from '@tiptap/extension-paragraph';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import ParagraphWrapper from '../components/wrappers/paragraph.vue';

export default Paragraph.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addKeyboardShortcuts() {
    return {
      ...this.parent?.(),
      'Shift-Enter': async () => {
        // can only delegate one shortcut to another async
        await Promise.resolve();
        this.editor.commands.enter();
      },
    };
  },

  addNodeView() {
    return VueNodeViewRenderer(ParagraphWrapper);
  },
});
