import { Node, textblockTypeInputRule } from '@tiptap/core';

export const commentInputRegex = /^<!--[\s\n]$/;

export default Node.create({
  name: 'comment',
  content: 'text*',
  marks: '',
  group: 'block',
  code: true,
  isolating: true,
  defining: true,

  parseHTML() {
    return [
      {
        tag: 'comment',
        preserveWhitespace: 'full',
        getContent(element, schema) {
          const node = schema.node('paragraph', {}, [
            schema.text(
              element.textContent.replace(/&#x([0-9A-F]{2,4});/gi, (_, code) =>
                String.fromCharCode(parseInt(code, 16)),
              ) || ' ',
            ),
          ]);
          return node.content;
        },
      },
    ];
  },

  renderHTML() {
    return [
      'pre',
      { class: 'gl-p-0 gl-border-0 gl-bg-transparent gl-text-gray-300' },
      ['span', { class: 'content-editor-comment' }, 0],
    ];
  },

  addInputRules() {
    return [
      textblockTypeInputRule({
        find: commentInputRegex,
        type: this.type,
      }),
    ];
  },
});
