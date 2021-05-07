import { Node } from '@tiptap/core';

export const createTestContentEditorExtension = () => ({
  tiptapExtension: Node.create({
    name: 'label',
    priority: 101,
    inline: true,
    group: 'inline',
    addAttributes() {
      return {
        labelName: {
          default: null,
          parseHTML: (element) => {
            return { labelName: element.dataset.labelName };
          },
        },
      };
    },
    parseHTML() {
      return [
        {
          tag: 'span[data-reference="label"]',
        },
      ];
    },
    renderHTML({ HTMLAttributes }) {
      return ['span', HTMLAttributes, 0];
    },
  }),
  serializer: (state, node) => {
    state.write(`~${node.attrs.labelName}`);
    state.closeBlock(node);
  },
});
