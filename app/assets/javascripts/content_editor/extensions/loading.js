import { Node } from '@tiptap/core';

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

  renderHTML() {
    return [
      'span',
      { class: 'gl-display-inline-flex gl-align-items-center' },
      ['span', { class: 'gl-dots-loader gl-mx-2' }, ['span']],
    ];
  },
});
