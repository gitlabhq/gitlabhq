import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { handleFileEvent } from '../services/upload_helpers';

const processFiles = ({ files, uploadsPath, renderMarkdown, eventHub, editor }) => {
  if (!files.length) {
    return false;
  }

  let handled = true;

  for (const file of files) {
    handled = handled && handleFileEvent({ editor, file, uploadsPath, renderMarkdown, eventHub });
  }

  return handled;
};

export default Extension.create({
  name: 'attachment',

  addOptions() {
    return {
      uploadsPath: null,
      renderMarkdown: null,
      eventHub: null,
    };
  },

  addCommands() {
    return {
      uploadAttachment:
        ({ file }) =>
        () => {
          const { uploadsPath, renderMarkdown, eventHub } = this.options;

          return handleFileEvent({
            file,
            uploadsPath,
            renderMarkdown,
            editor: this.editor,
            eventHub,
          });
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
            return processFiles({
              files: event.clipboardData.files,
              editor,
              ...this.options,
            });
          },
          handleDrop: (_, event) => {
            return processFiles({
              files: event.dataTransfer.files,
              editor,
              ...this.options,
            });
          },
        },
      }),
    ];
  },
});
