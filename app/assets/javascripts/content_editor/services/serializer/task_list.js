import bulletList from './bullet_list';
import orderedList from './ordered_list';

function taskList(state, node) {
  if (node.attrs.numeric) orderedList(state, node);
  else bulletList(state, node);
}

export default taskList;
