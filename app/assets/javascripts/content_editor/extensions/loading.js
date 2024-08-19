import { Node } from '@tiptap/core';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import { Plugin } from '@tiptap/pm/state';

const createDotsLoader = () => {
  const root = document.createElement('span');
  root.classList.add('gl-inline-flex', 'gl-items-center');
  root.innerHTML = '<span class="gl-dots-loader gl-mx-2"><span></span></span>';
  return root;
};

export const loadingPlugin = new Plugin({
  state: {
    init() {
      return DecorationSet.empty;
    },
    apply(tr, set) {
      let transformedSet = set.map(tr.mapping, tr.doc);
      const action = tr.getMeta(this);

      if (action?.add) {
        const deco = Decoration.widget(action.add.pos, createDotsLoader(), {
          id: action.add.loaderId,
          side: -1,
        });
        transformedSet = transformedSet.add(tr.doc, [deco]);
      } else if (action?.remove) {
        transformedSet = transformedSet.remove(
          transformedSet.find(null, null, (spec) => spec.id === action.remove.loaderId),
        );
      }
      return transformedSet;
    },
  },
  props: {
    decorations(state) {
      return this.getState(state);
    },
  },
});

export const findLoader = (state, loaderId) => {
  const decos = loadingPlugin.getState(state);
  const found = decos.find(null, null, (spec) => spec.id === loaderId);

  return found.length ? found[0].from : null;
};

export const findAllLoaders = (state) => loadingPlugin.getState(state).find();

export default Node.create({
  name: 'loading',
  inline: true,
  group: 'inline',

  addAttributes() {
    return {
      id: {
        default: null,
      },
    };
  },

  addProseMirrorPlugins() {
    return [loadingPlugin];
  },
});
