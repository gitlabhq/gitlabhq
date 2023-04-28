import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';

export default Extension.create({
  name: 'selection',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('selection'),
        props: {
          decorations(state) {
            if (state.selection.empty) return null;

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
