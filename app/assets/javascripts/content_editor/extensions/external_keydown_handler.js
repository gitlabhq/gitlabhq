import { Extension } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { KEYDOWN_EVENT } from '../constants';

/**
 * This extension bubbles up the keydown event, captured by ProseMirror in the
 * contenteditale element, to the presentation layer implemented in vue.
 *
 * The purpose of this mechanism is allowing clients of the
 * content editor to attach keyboard shortcuts for behavior outside
 * of the Content Editor’s boundaries, i.e. submitting a form to save changes.
 */
export default Extension.create({
  name: 'keyboardShortcut',
  addOptions() {
    return {
      eventHub: null,
    };
  },
  addProseMirrorPlugins() {
    return [
      new Plugin({
        key: new PluginKey('keyboardShortcut'),
        props: {
          handleKeyDown: (_, event) => {
            const {
              options: { eventHub },
            } = this;

            eventHub.$emit(KEYDOWN_EVENT, event);

            return false;
          },
        },
      }),
    ];
  },
});
