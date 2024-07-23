import { preserveUnchanged } from '../serialization_helpers';

const footnoteReference = preserveUnchanged({
  render: (state, node) => {
    state.write(`[^${node.attrs.identifier}]`);
  },
  inline: true,
});

export default footnoteReference;
