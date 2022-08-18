import { Node } from '@tiptap/core';

export default Node.create({
  name: 'referenceDefinition',

  group: 'block',

  content: 'text*',

  marks: '',

  addAttributes() {
    return {
      identifier: {
        default: null,
      },
      url: {
        default: null,
      },
      title: {
        default: null,
      },
    };
  },

  renderHTML() {
    return ['pre', {}, 0];
  },
});
