import { sortTree } from '~/ide/stores/utils';
import { generateTreeList } from '../store/utils';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', e => {
  const { data } = e;
  const { treeEntries, tree } = generateTreeList(data);

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    treeEntries,
    tree: sortTree(tree),
  });
});
