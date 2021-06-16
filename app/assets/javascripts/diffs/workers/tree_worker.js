import { sortTree } from '~/ide/stores/utils';
import { generateTreeList } from '../utils/workers';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', (e) => {
  const { data } = e;

  if (data === undefined) {
    return;
  }

  const { treeEntries, tree } = generateTreeList(data);

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    treeEntries,
    tree: sortTree(tree),
  });
});
