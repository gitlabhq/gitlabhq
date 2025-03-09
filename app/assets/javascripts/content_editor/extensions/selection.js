import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';

export default Extension.create({
  name: 'selection',

  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('selection'),

        state: {
          init() {
            return DecorationSet.empty;
          },

          apply: (transaction, oldState) => {
            const { selection, doc } = transaction;
            const meta = transaction.getMeta('selection');
            const hasSelection = selection && selection.from !== selection.to;

            if (!hasSelection || meta?.action === 'focus') return DecorationSet.empty;
            if (hasSelection && meta?.action === 'blur') {
              return DecorationSet.create(doc, [
                Decoration.inline(selection.from, selection.to, {
                  class: 'content-editor-selection',
                }),
              ]);
            }

            return oldState;
          },
        },

        props: {
          decorations(state) {
            return this.getState(state);
          },
          handleDOMEvents: {
            blur: (view) => {
              const { tr } = view.state;

              view.dispatch(
                tr.setMeta('selection', {
                  from: tr.selection.from,
                  to: tr.selection.to,
                  action: 'blur',
                }),
              );
            },

            focus: (view) => {
              const { tr } = view.state;

              view.dispatch(
                tr.setMeta('selection', {
                  from: tr.selection.from,
                  to: tr.selection.to,
                  action: 'focus',
                }),
              );
            },
          },
        },
      }),
    ];
  },
});
