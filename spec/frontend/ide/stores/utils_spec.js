import * as utils from '~/ide/stores/utils';
import { commitActionTypes } from '~/ide/constants';
import { file } from '../helpers';

describe('Multi-file store utils', () => {
  describe('setPageTitle', () => {
    it('sets the document page title', () => {
      utils.setPageTitle('test');

      expect(document.title).toBe('test');
    });
  });

  describe('setPageTitleForFile', () => {
    it('sets the document page title for the file passed', () => {
      const f = {
        path: 'README.md',
      };

      const state = {
        currentBranchId: 'master',
        currentProjectId: 'test/test',
      };

      utils.setPageTitleForFile(state, f);

      expect(document.title).toBe('README.md · master · test/test · GitLab');
    });
  });

  describe('findIndexOfFile', () => {
    let localState;

    beforeEach(() => {
      localState = [
        {
          path: '1',
        },
        {
          path: '2',
        },
      ];
    });

    it('finds in the index of an entry by path', () => {
      const index = utils.findIndexOfFile(localState, {
        path: '2',
      });

      expect(index).toBe(1);
    });
  });

  describe('findEntry', () => {
    let localState;

    beforeEach(() => {
      localState = {
        tree: [
          {
            type: 'tree',
            name: 'test',
          },
          {
            type: 'blob',
            name: 'file',
          },
        ],
      };
    });

    it('returns an entry found by name', () => {
      const foundEntry = utils.findEntry(localState.tree, 'tree', 'test');

      expect(foundEntry.type).toBe('tree');
      expect(foundEntry.name).toBe('test');
    });

    it('returns undefined when no entry found', () => {
      const foundEntry = utils.findEntry(localState.tree, 'blob', 'test');

      expect(foundEntry).toBeUndefined();
    });
  });

  describe('createCommitPayload', () => {
    it('returns API payload', () => {
      const state = {
        commitMessage: 'commit message',
      };
      const rootState = {
        stagedFiles: [
          {
            ...file('staged'),
            path: 'staged',
            content: 'updated file content',
            lastCommitSha: '123456789',
          },
          {
            ...file('newFile'),
            path: 'added',
            tempFile: true,
            content: 'new file content',
            base64: true,
            lastCommitSha: '123456789',
          },
          { ...file('deletedFile'), path: 'deletedFile', deleted: true },
          { ...file('renamedFile'), path: 'renamedFile', prevPath: 'prevPath' },
          { ...file('replacingFile'), path: 'replacingFile', replaces: true },
        ],
        currentBranchId: 'master',
      };
      const payload = utils.createCommitPayload({
        branch: 'master',
        newBranch: false,
        state,
        rootState,
        getters: {},
      });

      expect(payload).toEqual({
        branch: 'master',
        commit_message: 'commit message',
        actions: [
          {
            action: commitActionTypes.update,
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.create,
            file_path: 'added',
            content: 'new file content',
            encoding: 'base64',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.delete,
            file_path: 'deletedFile',
            content: undefined,
            encoding: 'text',
            last_commit_id: undefined,
            previous_path: undefined,
          },
          {
            action: commitActionTypes.move,
            file_path: 'renamedFile',
            content: null,
            encoding: 'text',
            last_commit_id: undefined,
            previous_path: 'prevPath',
          },
          {
            action: commitActionTypes.update,
            file_path: 'replacingFile',
            content: undefined,
            encoding: 'text',
            last_commit_id: undefined,
            previous_path: undefined,
          },
        ],
        start_sha: undefined,
      });
    });

    it('uses prebuilt commit message when commit message is empty', () => {
      const rootState = {
        stagedFiles: [
          {
            ...file('staged'),
            path: 'staged',
            content: 'updated file content',
            lastCommitSha: '123456789',
          },
          {
            ...file('newFile'),
            path: 'added',
            tempFile: true,
            content: 'new file content',
            base64: true,
            lastCommitSha: '123456789',
          },
        ],
        currentBranchId: 'master',
      };
      const payload = utils.createCommitPayload({
        branch: 'master',
        newBranch: false,
        state: {},
        rootState,
        getters: {
          preBuiltCommitMessage: 'prebuilt test commit message',
        },
      });

      expect(payload).toEqual({
        branch: 'master',
        commit_message: 'prebuilt test commit message',
        actions: [
          {
            action: commitActionTypes.update,
            file_path: 'staged',
            content: 'updated file content',
            encoding: 'text',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
          {
            action: commitActionTypes.create,
            file_path: 'added',
            content: 'new file content',
            encoding: 'base64',
            last_commit_id: '123456789',
            previous_path: undefined,
          },
        ],
        start_sha: undefined,
      });
    });
  });

  describe('commitActionForFile', () => {
    it('returns deleted for deleted file', () => {
      expect(
        utils.commitActionForFile({
          deleted: true,
        }),
      ).toBe(commitActionTypes.delete);
    });

    it('returns create for tempFile', () => {
      expect(
        utils.commitActionForFile({
          tempFile: true,
        }),
      ).toBe(commitActionTypes.create);
    });

    it('returns move for moved file', () => {
      expect(
        utils.commitActionForFile({
          prevPath: 'test',
        }),
      ).toBe(commitActionTypes.move);
    });

    it('returns update by default', () => {
      expect(utils.commitActionForFile({})).toBe(commitActionTypes.update);
    });
  });

  describe('getCommitFiles', () => {
    it('filters out folders from the list', () => {
      const files = [
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'c',
          type: 'tree',
          deleted: true,
        },
        {
          path: 'c/d',
          type: 'blob',
          deleted: true,
        },
      ];

      const flattendFiles = utils.getCommitFiles(files);

      expect(flattendFiles).toEqual([
        {
          path: 'a',
          type: 'blob',
          deleted: true,
        },
        {
          path: 'c/d',
          type: 'blob',
          deleted: true,
        },
      ]);
    });
  });

  describe('mergeTrees', () => {
    let fromTree;
    let toTree;

    beforeEach(() => {
      fromTree = [file('foo')];
      toTree = [file('bar')];
    });

    it('merges simple trees with sorting the result', () => {
      toTree = [file('beta'), file('alpha'), file('gamma')];
      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(4);
      expect(res[0].name).toEqual('alpha');
      expect(res[1].name).toEqual('beta');
      expect(res[2].name).toEqual('foo');
      expect(res[3].name).toEqual('gamma');
      expect(res[2]).toBe(fromTree[0]);
    });

    it('handles edge cases', () => {
      expect(utils.mergeTrees({}, []).length).toEqual(0);

      let res = utils.mergeTrees({}, toTree);

      expect(res.length).toEqual(1);
      expect(res[0].name).toEqual('bar');

      res = utils.mergeTrees(fromTree, []);

      expect(res.length).toEqual(1);
      expect(res[0].name).toEqual('foo');
      expect(res[0]).toBe(fromTree[0]);
    });

    it('merges simple trees without producing duplicates', () => {
      toTree.push(file('foo'));

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(2);
      expect(res[0].name).toEqual('bar');
      expect(res[1].name).toEqual('foo');
      expect(res[1]).not.toBe(fromTree[0]);
    });

    it('merges nested tree into the main one without duplicates', () => {
      fromTree[0].tree.push({
        ...file('alpha'),
        path: 'foo/alpha',
        tree: [{ ...file('beta.md'), path: 'foo/alpha/beta.md' }],
      });

      toTree.push({
        ...file('foo'),
        tree: [
          {
            ...file('alpha'),
            path: 'foo/alpha',
            tree: [{ ...file('gamma.md'), path: 'foo/alpha/gamma.md' }],
          },
        ],
      });

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res.length).toEqual(2);
      expect(res[1].name).toEqual('foo');

      const finalBranch = res[1].tree[0].tree;

      expect(finalBranch.length).toEqual(2);
      expect(finalBranch[0].name).toEqual('beta.md');
      expect(finalBranch[1].name).toEqual('gamma.md');
    });

    it('marks correct folders as opened as the parsing goes on', () => {
      fromTree[0].tree.push({
        ...file('alpha'),
        path: 'foo/alpha',
        tree: [{ ...file('beta.md'), path: 'foo/alpha/beta.md' }],
      });

      toTree.push({
        ...file('foo'),
        tree: [
          {
            ...file('alpha'),
            path: 'foo/alpha',
            tree: [{ ...file('gamma.md'), path: 'foo/alpha/gamma.md' }],
          },
        ],
      });

      const res = utils.mergeTrees(fromTree, toTree);

      expect(res[1].name).toEqual('foo');
      expect(res[1].opened).toEqual(true);

      expect(res[1].tree[0].name).toEqual('alpha');
      expect(res[1].tree[0].opened).toEqual(true);
    });
  });

  describe('swapInStateArray', () => {
    let localState;

    beforeEach(() => {
      localState = [];
    });

    it('swaps existing entry with a new one', () => {
      const file1 = { ...file('old'), key: 'foo' };
      const file2 = file('new');
      const arr = [file1];

      Object.assign(localState, {
        dummyArray: arr,
        entries: {
          new: file2,
        },
      });

      utils.swapInStateArray(localState, 'dummyArray', 'foo', 'new');

      expect(localState.dummyArray.length).toBe(1);
      expect(localState.dummyArray[0]).toBe(file2);
    });

    it('does not add an item if it does not exist yet in array', () => {
      const file1 = file('file');
      Object.assign(localState, {
        dummyArray: [],
        entries: {
          file: file1,
        },
      });

      utils.swapInStateArray(localState, 'dummyArray', 'foo', 'file');

      expect(localState.dummyArray.length).toBe(0);
    });
  });

  describe('swapInParentTreeWithSorting', () => {
    let localState;
    let branchInfo;
    const currentProjectId = '123-foo';
    const currentBranchId = 'master';

    beforeEach(() => {
      localState = {
        currentBranchId,
        currentProjectId,
        trees: {
          [`${currentProjectId}/${currentBranchId}`]: {
            tree: [],
          },
        },
        entries: {
          oldPath: file('oldPath', 'oldPath', 'blob'),
          newPath: file('newPath', 'newPath', 'blob'),
          parentPath: file('parentPath', 'parentPath', 'tree'),
        },
      };
      branchInfo = localState.trees[`${currentProjectId}/${currentBranchId}`];
    });

    it('does not change tree if newPath is not supplied', () => {
      branchInfo.tree = [localState.entries.oldPath];

      utils.swapInParentTreeWithSorting(localState, 'oldPath', undefined, undefined);

      expect(branchInfo.tree).toEqual([localState.entries.oldPath]);
    });

    describe('oldPath to replace is not defined: simple addition to tree', () => {
      it('adds to tree on the state if there is no parent for the entry', () => {
        expect(branchInfo.tree.length).toBe(0);

        utils.swapInParentTreeWithSorting(localState, undefined, 'oldPath', undefined);

        expect(branchInfo.tree.length).toBe(1);
        expect(branchInfo.tree[0].name).toBe('oldPath');

        utils.swapInParentTreeWithSorting(localState, undefined, 'newPath', undefined);

        expect(branchInfo.tree.length).toBe(2);
        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'newPath',
          }),
          expect.objectContaining({
            name: 'oldPath',
          }),
        ]);
      });

      it('adds to parent tree if it is supplied', () => {
        utils.swapInParentTreeWithSorting(localState, undefined, 'newPath', 'parentPath');

        expect(localState.entries.parentPath.tree.length).toBe(1);
        expect(localState.entries.parentPath.tree).toEqual([
          expect.objectContaining({
            name: 'newPath',
          }),
        ]);

        localState.entries.parentPath.tree = [localState.entries.oldPath];

        utils.swapInParentTreeWithSorting(localState, undefined, 'newPath', 'parentPath');

        expect(localState.entries.parentPath.tree.length).toBe(2);
        expect(localState.entries.parentPath.tree).toEqual([
          expect.objectContaining({
            name: 'newPath',
          }),
          expect.objectContaining({
            name: 'oldPath',
          }),
        ]);
      });
    });

    describe('swapping of the items', () => {
      it('swaps entries if both paths are supplied', () => {
        branchInfo.tree = [localState.entries.oldPath];

        utils.swapInParentTreeWithSorting(localState, localState.entries.oldPath.key, 'newPath');

        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'newPath',
          }),
        ]);

        utils.swapInParentTreeWithSorting(localState, localState.entries.newPath.key, 'oldPath');

        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'oldPath',
          }),
        ]);
      });

      it('sorts tree after swapping the entries', () => {
        const alpha = file('alpha', 'alpha', 'blob');
        const beta = file('beta', 'beta', 'blob');
        const gamma = file('gamma', 'gamma', 'blob');
        const theta = file('theta', 'theta', 'blob');
        localState.entries = {
          alpha,
          beta,
          gamma,
          theta,
        };

        branchInfo.tree = [alpha, beta, gamma];

        utils.swapInParentTreeWithSorting(localState, alpha.key, 'theta');

        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'beta',
          }),
          expect.objectContaining({
            name: 'gamma',
          }),
          expect.objectContaining({
            name: 'theta',
          }),
        ]);

        utils.swapInParentTreeWithSorting(localState, gamma.key, 'alpha');

        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'alpha',
          }),
          expect.objectContaining({
            name: 'beta',
          }),
          expect.objectContaining({
            name: 'theta',
          }),
        ]);

        utils.swapInParentTreeWithSorting(localState, beta.key, 'gamma');

        expect(branchInfo.tree).toEqual([
          expect.objectContaining({
            name: 'alpha',
          }),
          expect.objectContaining({
            name: 'gamma',
          }),
          expect.objectContaining({
            name: 'theta',
          }),
        ]);
      });
    });
  });

  describe('cleanTrailingSlash', () => {
    [
      {
        input: '',
        output: '',
      },
      {
        input: 'abc',
        output: 'abc',
      },
      {
        input: 'abc/',
        output: 'abc',
      },
      {
        input: 'abc/def',
        output: 'abc/def',
      },
      {
        input: 'abc/def/',
        output: 'abc/def',
      },
    ].forEach(({ input, output }) => {
      it(`cleans trailing slash from string "${input}"`, () => {
        expect(utils.cleanTrailingSlash(input)).toEqual(output);
      });
    });
  });

  describe('pathsAreEqual', () => {
    [
      {
        args: ['abc', 'abc'],
        output: true,
      },
      {
        args: ['abc', 'def'],
        output: false,
      },
      {
        args: ['abc/', 'abc'],
        output: true,
      },
      {
        args: ['abc/abc', 'abc'],
        output: false,
      },
      {
        args: ['/', ''],
        output: true,
      },
      {
        args: ['', '/'],
        output: true,
      },
      {
        args: [false, '/'],
        output: true,
      },
    ].forEach(({ args, output }) => {
      it(`cleans and tests equality (${JSON.stringify(args)})`, () => {
        expect(utils.pathsAreEqual(...args)).toEqual(output);
      });
    });
  });

  describe('addFinalNewlineIfNeeded', () => {
    it('adds a newline if it doesnt already exist', () => {
      [
        {
          input: 'some text',
          output: 'some text\n',
        },
        {
          input: 'some text\n',
          output: 'some text\n',
        },
        {
          input: 'some text\n\n',
          output: 'some text\n\n',
        },
        {
          input: 'some\n text',
          output: 'some\n text\n',
        },
      ].forEach(({ input, output }) => {
        expect(utils.addFinalNewlineIfNeeded(input)).toEqual(output);
      });
    });
  });
});
