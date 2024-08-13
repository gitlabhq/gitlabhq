import { preserveUnchanged } from '../serialization_helpers';

const listItem = preserveUnchanged((state, node) => {
  state.renderContent(node);
});

export default listItem;
