import { preserveUnchanged } from '../serialization_helpers';

const taskItem = preserveUnchanged((state, node) => {
  let symbol = ' ';
  if (node.attrs.inapplicable) symbol = '~';
  else if (node.attrs.checked) symbol = 'x';

  state.write(`[${symbol}] `);

  state.renderContent(node);
});

export default taskItem;
