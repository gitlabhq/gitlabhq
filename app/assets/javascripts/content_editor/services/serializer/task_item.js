import { containsEmptyParagraph } from '../serialization_helpers';

function taskItem(state, node) {
  let symbol = ' ';
  if (node.attrs.inapplicable) symbol = '~';
  else if (node.attrs.checked) symbol = 'x';

  state.write(`[${symbol}]`);

  if (node.childCount > 0 && !containsEmptyParagraph(node)) {
    state.write(' ');
    state.renderContent(node);
  }
}

export default taskItem;
