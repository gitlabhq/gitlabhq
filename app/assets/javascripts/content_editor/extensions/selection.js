import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';

export default Extension.create({
  name: 'selection',

  addProseMirrorPlugins() {
    let contextMenuVisible = false;

    return [
      new Plugin({
        key: new PluginKey('selection'),
        props: {
          handleDOMEvents: {
            contextmenu() {
              contextMenuVisible = true;
              setTimeout(() => {
                contextMenuVisible = false;
              });
            },
          },
          decorations(state) {
            if (state.selection.empty || contextMenuVisible) return null;

            return DecorationSet.create(state.doc, [
              Decoration.inline(state.selection.from, state.selection.to, {
                class: 'content-editor-selection',
              }),
            ]);
          },
        },
      }),
    ];
  },
});
