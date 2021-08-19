import { Node } from '@tiptap/core';
import { InputRule } from 'prosemirror-inputrules';
import { initEmojiMap, getAllEmoji } from '~/emoji';

export const emojiInputRegex = /(?:^|\s)((?::)((?:\w+))(?::))$/;

export default Node.create({
  name: 'emoji',

  inline: true,

  group: 'inline',

  draggable: true,

  addAttributes() {
    return {
      moji: {
        default: null,
        parseHTML: (element) => {
          return {
            moji: element.textContent,
          };
        },
      },
      name: {
        default: null,
        parseHTML: (element) => {
          return {
            name: element.dataset.name,
          };
        },
      },
      title: {
        default: null,
      },
      unicodeVersion: {
        default: '6.0',
        parseHTML: (element) => {
          return {
            unicodeVersion: element.dataset.unicodeVersion,
          };
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'gl-emoji',
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'gl-emoji',
      {
        'data-name': node.attrs.name,
        title: node.attrs.title,
        'data-unicode-version': node.attrs.unicodeVersion,
      },
      node.attrs.moji,
    ];
  },

  addInputRules() {
    return [
      new InputRule(emojiInputRegex, (state, match, start, end) => {
        const [, , name] = match;
        const emojis = getAllEmoji();
        const emoji = emojis[name];
        const { tr } = state;

        if (emoji) {
          tr.replaceWith(start, end, [
            state.schema.text(' '),
            this.type.create({ name, moji: emoji.e, unicodeVersion: emoji.u, title: emoji.d }),
          ]);

          return tr;
        }

        return null;
      }),
    ];
  },

  onCreate() {
    initEmojiMap();
  },
});
