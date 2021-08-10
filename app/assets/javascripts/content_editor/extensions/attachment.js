import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from 'prosemirror-state';
import { handleFileEvent } from '../services/upload_helpers';

export default Extension.create({
  name: 'attachment',

  defaultOptions: {
    uploadsPath: null,
    renderMarkdown: null,
  },

  addCommands() {
    return {
      uploadAttachment: ({ file }) => () => {
        const { uploadsPath, renderMarkdown } = this.options;

        return handleFileEvent({ file, uploadsPath, renderMarkdown, editor: this.editor });
      },
    };
  },
  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      new Plugin({
        key: new PluginKey('attachment'),
        props: {
          handlePaste: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              file: event.clipboardData.files[0],
              uploadsPath,
              renderMarkdown,
            });
          },
          handleDrop: (_, event) => {
            const { uploadsPath, renderMarkdown } = this.options;

            return handleFileEvent({
              editor,
              file: event.dataTransfer.files[0],
              uploadsPath,
              renderMarkdown,
            });
          },
        },
      }),
    ];
  },
});
