import { preserveUnchanged } from '../serialization_helpers';
import { renderBulletList } from './bullet_list';
import { renderOrderedList } from './ordered_list';

const taskList = preserveUnchanged((state, node) => {
  if (node.attrs.numeric) renderOrderedList(state, node);
  else renderBulletList(state, node);
});

export default taskList;
