import { HardBreak } from '@tiptap/extension-hard-break';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

const ExtendedHardBreak = HardBreak.extend({
  addKeyboardShortcuts() {
    return {
      'Shift-Enter': () => this.editor.commands.setHardBreak(),
    };
  },
});

export const tiptapExtension = ExtendedHardBreak;
export const serializer = defaultMarkdownSerializer.nodes.hard_break;
