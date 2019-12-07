import mutations from '~/ide/stores/mutations/tree';
import state from '~/ide/stores/state';
import { file } from '../../helpers';

describe('Multi-file store tree mutations', () => {
  let localState;
  let localTree;

  beforeEach(() => {
    localState = state();
    localTree = file();

    localState.entries[localTree.path] = localTree;
  });

  describe('TOGGLE_TREE_OPEN', () => {
    it('toggles tree open', () => {
      mutations.TOGGLE_TREE_OPEN(localState, localTree.path);

      expect(localTree.opened).toBeTruthy();

      mutations.TOGGLE_TREE_OPEN(localState, localTree.path);

      expect(localTree.opened).toBeFalsy();
    });
  });

  describe('SET_DIRECTORY_DATA', () => {
    let data;

    beforeEach(() => {
      data = [file('tree'), file('foo'), file('blob')];
    });

    it('adds directory data', () => {
      localState.trees['project/master'] = {
        tree: [],
      };

      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        treePath: 'project/master',
      });

      const tree = localState.trees['project/master'];

      expect(tree.tree.length).toBe(3);
      expect(tree.tree[0].name).toBe('tree');
      expect(tree.tree[1].name).toBe('foo');
      expect(tree.tree[2].name).toBe('blob');
    });

    it('keeps loading state', () => {
      mutations.CREATE_TREE(localState, {
        treePath: 'project/master',
      });
      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        treePath: 'project/master',
      });

      expect(localState.trees['project/master'].loading).toBe(true);
    });

    it('does not override tree already in state, but merges the two with correct order', () => {
      const openedFile = file('new');

      localState.trees['project/master'] = {
        loading: true,
        tree: [openedFile],
      };

      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        treePath: 'project/master',
      });

      const { tree } = localState.trees['project/master'];

      expect(tree.length).toBe(4);
      expect(tree[0].name).toBe('blob');
      expect(tree[1].name).toBe('foo');
      expect(tree[2].name).toBe('new');
      expect(tree[3].name).toBe('tree');
    });

    it('returns tree unchanged if the opened file is already in the tree', () => {
      const openedFile = file('foo');
      localState.trees['project/master'] = {
        loading: true,
        tree: [openedFile],
      };

      mutations.SET_DIRECTORY_DATA(localState, {
        data,
        treePath: 'project/master',
      });

      const { tree } = localState.trees['project/master'];

      expect(tree.length).toBe(3);

      expect(tree[0].name).toBe('tree');
      expect(tree[1].name).toBe('foo');
      expect(tree[2].name).toBe('blob');
    });
  });

  describe('REMOVE_ALL_CHANGES_FILES', () => {
    it('removes all files from changedFiles state', () => {
      localState.changedFiles.push(file('REMOVE_ALL_CHANGES_FILES'));

      mutations.REMOVE_ALL_CHANGES_FILES(localState);

      expect(localState.changedFiles.length).toBe(0);
    });
  });
});
