import { Node } from '@tiptap/core';

export default Node.create({
  name: 'loading',
  inline: true,
  group: 'inline',

  addAttributes() {
    return {
      label: {
        default: null,
      },
    };
  },

  renderHTML({ node }) {
    return [
      'span',
      { class: 'gl-display-inline-flex gl-align-items-center' },
      ['span', { class: 'gl-spinner gl-mx-2' }],
      ['span', { class: 'gl-link' }, node.attrs.label],
    ];
  },
});
