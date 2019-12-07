import { TEST_HOST } from 'helpers/test_constants';
import mutations from '~/ide/stores/mutations';
import state from '~/ide/stores/state';
import { file } from '../helpers';

describe('Multi-file store mutations', () => {
  let localState;
  let entry;

  beforeEach(() => {
    localState = state();
    entry = file();

    localState.entries[entry.path] = entry;
  });

  describe('SET_INITIAL_DATA', () => {
    it('sets all initial data', () => {
      mutations.SET_INITIAL_DATA(localState, {
        test: 'test',
      });

      expect(localState.test).toBe('test');
    });
  });

  describe('TOGGLE_LOADING', () => {
    it('toggles loading of entry', () => {
      mutations.TOGGLE_LOADING(localState, {
        entry,
      });

      expect(entry.loading).toBeTruthy();

      mutations.TOGGLE_LOADING(localState, {
        entry,
      });

      expect(entry.loading).toBeFalsy();
    });

    it('toggles loading of entry and sets specific value', () => {
      mutations.TOGGLE_LOADING(localState, {
        entry,
      });

      expect(entry.loading).toBeTruthy();

      mutations.TOGGLE_LOADING(localState, {
        entry,
        forceValue: true,
      });

      expect(entry.loading).toBeTruthy();
    });
  });

  describe('SET_LEFT_PANEL_COLLAPSED', () => {
    it('sets left panel collapsed', () => {
      mutations.SET_LEFT_PANEL_COLLAPSED(localState, true);

      expect(localState.leftPanelCollapsed).toBeTruthy();

      mutations.SET_LEFT_PANEL_COLLAPSED(localState, false);

      expect(localState.leftPanelCollapsed).toBeFalsy();
    });
  });

  describe('SET_RIGHT_PANEL_COLLAPSED', () => {
    it('sets right panel collapsed', () => {
      mutations.SET_RIGHT_PANEL_COLLAPSED(localState, true);

      expect(localState.rightPanelCollapsed).toBeTruthy();

      mutations.SET_RIGHT_PANEL_COLLAPSED(localState, false);

      expect(localState.rightPanelCollapsed).toBeFalsy();
    });
  });

  describe('CLEAR_STAGED_CHANGES', () => {
    it('clears stagedFiles array', () => {
      localState.stagedFiles.push('a');

      mutations.CLEAR_STAGED_CHANGES(localState);

      expect(localState.stagedFiles.length).toBe(0);
    });
  });

  describe('UPDATE_VIEWER', () => {
    it('sets viewer state', () => {
      mutations.UPDATE_VIEWER(localState, 'diff');

      expect(localState.viewer).toBe('diff');
    });
  });

  describe('UPDATE_ACTIVITY_BAR_VIEW', () => {
    it('updates currentActivityBar', () => {
      mutations.UPDATE_ACTIVITY_BAR_VIEW(localState, 'test');

      expect(localState.currentActivityView).toBe('test');
    });
  });

  describe('SET_EMPTY_STATE_SVGS', () => {
    it('updates empty state SVGs', () => {
      mutations.SET_EMPTY_STATE_SVGS(localState, {
        emptyStateSvgPath: 'emptyState',
        noChangesStateSvgPath: 'noChanges',
        committedStateSvgPath: 'commited',
      });

      expect(localState.emptyStateSvgPath).toBe('emptyState');
      expect(localState.noChangesStateSvgPath).toBe('noChanges');
      expect(localState.committedStateSvgPath).toBe('commited');
    });
  });

  describe('CREATE_TMP_ENTRY', () => {
    beforeEach(() => {
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.trees['gitlab-ce/master'] = {
        tree: [],
      };
    });

    it('creates temp entry in the tree', () => {
      const tmpFile = file('test');
      mutations.CREATE_TMP_ENTRY(localState, {
        data: {
          entries: {
            test: { ...tmpFile, tempFile: true, changed: true },
          },
          treeList: [tmpFile],
        },
        projectId: 'gitlab-ce',
        branchId: 'master',
      });

      expect(localState.trees['gitlab-ce/master'].tree.length).toEqual(1);
      expect(localState.entries.test.tempFile).toEqual(true);
    });

    it('marks entry as replacing previous entry if the old one has been deleted', () => {
      const tmpFile = file('test');
      localState.entries.test = { ...tmpFile, deleted: true };
      mutations.CREATE_TMP_ENTRY(localState, {
        data: {
          entries: {
            test: { ...tmpFile, tempFile: true, changed: true },
          },
          treeList: [tmpFile],
        },
        projectId: 'gitlab-ce',
        branchId: 'master',
      });

      expect(localState.trees['gitlab-ce/master'].tree.length).toEqual(1);
      expect(localState.entries.test.replaces).toEqual(true);
    });
  });

  describe('UPDATE_TEMP_FLAG', () => {
    beforeEach(() => {
      localState.entries.test = { ...file(), tempFile: true, changed: true };
    });

    it('updates tempFile flag', () => {
      mutations.UPDATE_TEMP_FLAG(localState, {
        path: 'test',
        tempFile: false,
      });

      expect(localState.entries.test.tempFile).toBe(false);
    });

    it('updates changed flag', () => {
      mutations.UPDATE_TEMP_FLAG(localState, {
        path: 'test',
        tempFile: false,
      });

      expect(localState.entries.test.changed).toBe(false);
    });
  });

  describe('TOGGLE_FILE_FINDER', () => {
    it('updates fileFindVisible', () => {
      mutations.TOGGLE_FILE_FINDER(localState, true);

      expect(localState.fileFindVisible).toBe(true);
    });
  });

  describe('BURST_UNUSED_SEAL', () => {
    it('updates unusedSeal', () => {
      expect(localState.unusedSeal).toBe(true);

      mutations.BURST_UNUSED_SEAL(localState);

      expect(localState.unusedSeal).toBe(false);
    });
  });

  describe('SET_ERROR_MESSAGE', () => {
    it('updates error message', () => {
      mutations.SET_ERROR_MESSAGE(localState, 'error');

      expect(localState.errorMessage).toBe('error');
    });
  });

  describe('DELETE_ENTRY', () => {
    beforeEach(() => {
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.trees['gitlab-ce/master'] = {
        tree: [],
      };
    });

    it('sets deleted flag', () => {
      localState.entries.filePath = {
        deleted: false,
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.entries.filePath.deleted).toBe(true);
    });

    it('removes from root tree', () => {
      localState.entries.filePath = {
        path: 'filePath',
        deleted: false,
      };
      localState.trees['gitlab-ce/master'].tree.push(localState.entries.filePath);

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.trees['gitlab-ce/master'].tree).toEqual([]);
    });

    it('removes from parent tree', () => {
      localState.entries.filePath = {
        path: 'filePath',
        deleted: false,
        parentPath: 'parentPath',
      };
      localState.entries.parentPath = {
        tree: [localState.entries.filePath],
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.entries.parentPath.tree).toEqual([]);
    });

    it('adds to changedFiles', () => {
      localState.entries.filePath = {
        deleted: false,
        type: 'blob',
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.changedFiles).toEqual([localState.entries.filePath]);
    });

    it('does not add tempFile into changedFiles', () => {
      localState.entries.filePath = {
        deleted: false,
        type: 'blob',
        tempFile: true,
      };

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.changedFiles).toEqual([]);
    });

    it('removes tempFile from changedFiles when deleted', () => {
      localState.entries.filePath = {
        path: 'filePath',
        deleted: false,
        type: 'blob',
        tempFile: true,
      };

      localState.changedFiles.push({ ...localState.entries.filePath });

      mutations.DELETE_ENTRY(localState, 'filePath');

      expect(localState.changedFiles).toEqual([]);
    });
  });

  describe('UPDATE_FILE_AFTER_COMMIT', () => {
    it('updates URLs if prevPath is set', () => {
      const f = {
        ...file('test'),
        prevPath: 'testing-123',
        rawPath: `${TEST_HOST}/testing-123`,
        permalink: `${TEST_HOST}/testing-123`,
        commitsPath: `${TEST_HOST}/testing-123`,
        blamePath: `${TEST_HOST}/testing-123`,
        replaces: true,
      };
      localState.entries.test = f;
      localState.changedFiles.push(f);

      mutations.UPDATE_FILE_AFTER_COMMIT(localState, {
        file: f,
        lastCommit: {
          commit: {},
        },
      });

      expect(f).toEqual(
        expect.objectContaining({
          rawPath: `${TEST_HOST}/test`,
          permalink: `${TEST_HOST}/test`,
          commitsPath: `${TEST_HOST}/test`,
          blamePath: `${TEST_HOST}/test`,
          replaces: false,
          prevId: undefined,
          prevPath: undefined,
          prevName: undefined,
          prevUrl: undefined,
          prevKey: undefined,
        }),
      );
    });
  });

  describe('OPEN_NEW_ENTRY_MODAL', () => {
    it('sets entryModal', () => {
      localState.entries.testPath = file();

      mutations.OPEN_NEW_ENTRY_MODAL(localState, {
        type: 'test',
        path: 'testPath',
      });

      expect(localState.entryModal).toEqual({
        type: 'test',
        path: 'testPath',
        entry: localState.entries.testPath,
      });
    });
  });

  describe('RENAME_ENTRY', () => {
    beforeEach(() => {
      localState.trees = {
        'gitlab-ce/master': {
          tree: [],
        },
      };
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.entries = {
        oldPath: file('oldPath', 'oldPath', 'blob'),
      };
    });

    it('updates existing entry without creating a new one', () => {
      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
        parentPath: '',
      });

      expect(localState.entries).toEqual({
        newPath: expect.objectContaining({
          path: 'newPath',
          prevPath: 'oldPath',
        }),
      });
    });

    it('correctly handles consecutive renames for the same entry', () => {
      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
        parentPath: '',
      });

      mutations.RENAME_ENTRY(localState, {
        path: 'newPath',
        name: 'newestPath',
        parentPath: '',
      });

      expect(localState.entries).toEqual({
        newestPath: expect.objectContaining({
          path: 'newestPath',
          prevPath: 'oldPath',
        }),
      });
    });

    it('correctly handles the same entry within a consecutively renamed folder', () => {
      const oldPath = file('root-folder/oldPath', 'root-folder/oldPath', 'blob');
      localState.entries = {
        'root-folder': { ...file('root-folder', 'root-folder', 'tree'), tree: [oldPath] },
        'root-folder/oldPath': oldPath,
      };
      Object.assign(localState.entries['root-folder/oldPath'], {
        parentPath: 'root-folder',
        url: 'root-folder/oldPath-blob-root-folder/oldPath',
      });

      mutations.RENAME_ENTRY(localState, {
        path: 'root-folder/oldPath',
        name: 'renamed-folder/oldPath',
        entryPath: null,
        parentPath: '',
      });

      mutations.RENAME_ENTRY(localState, {
        path: 'renamed-folder/oldPath',
        name: 'simply-renamed/oldPath',
        entryPath: null,
        parentPath: '',
      });

      expect(localState.entries).toEqual({
        'root-folder': expect.objectContaining({
          path: 'root-folder',
        }),
        'simply-renamed/oldPath': expect.objectContaining({
          path: 'simply-renamed/oldPath',
          prevPath: 'root-folder/oldPath',
        }),
      });
    });

    it('renames entry, preserving old parameters', () => {
      Object.assign(localState.entries.oldPath, {
        url: `project/-/oldPath`,
      });
      const oldPathData = localState.entries.oldPath;

      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
        parentPath: '',
      });

      expect(localState.entries.newPath).toEqual({
        ...oldPathData,
        id: 'newPath',
        path: 'newPath',
        name: 'newPath',
        url: `project/-/newPath`,
        key: expect.stringMatching('newPath'),
        prevId: 'oldPath',
        prevName: 'oldPath',
        prevPath: 'oldPath',
        prevUrl: `project/-/oldPath`,
        prevKey: oldPathData.key,
        prevParentPath: oldPathData.parentPath,
      });
    });

    it('does not store previous attributes on temp files', () => {
      Object.assign(localState.entries.oldPath, {
        tempFile: true,
      });
      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
        entryPath: null,
        parentPath: '',
      });

      expect(localState.entries.newPath).not.toEqual(
        expect.objectContaining({
          prevId: expect.anything(),
          prevName: expect.anything(),
          prevPath: expect.anything(),
          prevUrl: expect.anything(),
          prevKey: expect.anything(),
          prevParentPath: expect.anything(),
        }),
      );
    });

    it('properly handles files with spaces in name', () => {
      const path = 'my fancy path';
      const newPath = 'new path';
      const oldEntry = { ...file(path, path, 'blob'), url: `project/-/${encodeURI(path)}` };

      localState.entries[path] = oldEntry;

      mutations.RENAME_ENTRY(localState, {
        path,
        name: newPath,
        entryPath: null,
        parentPath: '',
      });

      expect(localState.entries[newPath]).toEqual({
        ...oldEntry,
        id: newPath,
        path: newPath,
        name: newPath,
        url: `project/-/new%20path`,
        key: expect.stringMatching(newPath),
        prevId: path,
        prevName: path,
        prevPath: path,
        prevUrl: `project/-/my%20fancy%20path`,
        prevKey: oldEntry.key,
        prevParentPath: oldEntry.parentPath,
      });
    });

    it('adds to parent tree', () => {
      const parentEntry = {
        ...file('parentPath', 'parentPath', 'tree'),
        tree: [localState.entries.oldPath],
      };
      localState.entries.parentPath = parentEntry;

      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
        entryPath: null,
        parentPath: 'parentPath',
      });

      expect(parentEntry.tree.length).toBe(1);
      expect(parentEntry.tree[0].name).toBe('newPath');
    });

    it('sorts tree after renaming an entry', () => {
      const alpha = file('alpha', 'alpha', 'blob');
      const beta = file('beta', 'beta', 'blob');
      const gamma = file('gamma', 'gamma', 'blob');
      localState.entries = {
        alpha,
        beta,
        gamma,
      };

      localState.trees['gitlab-ce/master'].tree = [alpha, beta, gamma];

      mutations.RENAME_ENTRY(localState, {
        path: 'alpha',
        name: 'theta',
        entryPath: null,
        parentPath: '',
      });

      expect(localState.trees['gitlab-ce/master'].tree).toEqual([
        expect.objectContaining({
          name: 'beta',
        }),
        expect.objectContaining({
          name: 'gamma',
        }),
        expect.objectContaining({
          path: 'theta',
          name: 'theta',
        }),
      ]);
    });

    it('updates openFiles with the renamed one if the original one is open', () => {
      Object.assign(localState.entries.oldPath, {
        opened: true,
        type: 'blob',
      });
      Object.assign(localState, {
        openFiles: [localState.entries.oldPath],
      });

      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
      });

      expect(localState.openFiles.length).toBe(1);
      expect(localState.openFiles[0].path).toBe('newPath');
    });

    it('does not add renamed entry to changedFiles', () => {
      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
      });

      expect(localState.changedFiles.length).toBe(0);
    });

    it('updates existing changedFiles entry with the renamed one', () => {
      const origFile = { ...file('oldPath', 'oldPath', 'blob'), content: 'Foo' };

      Object.assign(localState, {
        changedFiles: [origFile],
      });
      Object.assign(localState.entries, {
        oldPath: origFile,
      });

      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
      });

      expect(localState.changedFiles).toEqual([
        expect.objectContaining({
          path: 'newPath',
          content: 'Foo',
        }),
      ]);
    });

    it('correctly saves original values if an entry is renamed multiple times', () => {
      const original = { ...localState.entries.oldPath };
      const paramsToCheck = ['prevId', 'prevPath', 'prevName', 'prevUrl'];
      const expectedObj = paramsToCheck.reduce(
        (o, param) => ({ ...o, [param]: original[param.replace('prev', '').toLowerCase()] }),
        {},
      );

      mutations.RENAME_ENTRY(localState, {
        path: 'oldPath',
        name: 'newPath',
      });

      expect(localState.entries.newPath).toEqual(expect.objectContaining(expectedObj));

      mutations.RENAME_ENTRY(localState, {
        path: 'newPath',
        name: 'newer',
      });

      expect(localState.entries.newer).toEqual(expect.objectContaining(expectedObj));
    });

    describe('renaming back to original', () => {
      beforeEach(() => {
        const renamedEntry = {
          ...file('renamed', 'renamed', 'blob'),
          prevId: 'lorem/orig',
          prevPath: 'lorem/orig',
          prevName: 'orig',
          prevUrl: 'project/-/loren/orig',
          prevKey: 'lorem/orig',
          prevParentPath: 'lorem',
        };

        localState.entries = {
          renamed: renamedEntry,
        };

        mutations.RENAME_ENTRY(localState, {
          path: 'renamed',
          name: 'orig',
          parentPath: 'lorem',
        });
      });

      it('renames entry and clears prev properties', () => {
        expect(localState.entries).toEqual({
          'lorem/orig': expect.objectContaining({
            id: 'lorem/orig',
            path: 'lorem/orig',
            name: 'orig',
            prevId: undefined,
            prevPath: undefined,
            prevName: undefined,
            prevUrl: undefined,
            prevKey: undefined,
            prevParentPath: undefined,
          }),
        });
      });
    });

    describe('key updates', () => {
      beforeEach(() => {
        const rootFolder = file('rootFolder', 'rootFolder', 'tree');
        localState.entries = {
          rootFolder,
          oldPath: file('oldPath', 'oldPath', 'blob'),
          'oldPath.txt': file('oldPath.txt', 'oldPath.txt', 'blob'),
          'rootFolder/oldPath.md': file('oldPath.md', 'oldPath.md', 'blob', rootFolder),
        };
      });

      it('sets properly constucted key while preserving the original one', () => {
        const key = 'oldPath.txt-blob-oldPath.txt';
        localState.entries['oldPath.txt'].key = key;
        mutations.RENAME_ENTRY(localState, {
          path: 'oldPath.txt',
          name: 'newPath.md',
        });

        expect(localState.entries['newPath.md'].key).toBe('newPath.md-blob-newPath.md');
        expect(localState.entries['newPath.md'].prevKey).toBe(key);
      });

      it('correctly updates key for an entry without an extension', () => {
        localState.entries.oldPath.key = 'oldPath-blob-oldPath';
        mutations.RENAME_ENTRY(localState, {
          path: 'oldPath',
          name: 'newPath.md',
        });

        expect(localState.entries['newPath.md'].key).toBe('newPath.md-blob-newPath.md');
      });

      it('correctly updates key when new name does not have an extension', () => {
        localState.entries['oldPath.txt'].key = 'oldPath.txt-blob-oldPath.txt';
        mutations.RENAME_ENTRY(localState, {
          path: 'oldPath.txt',
          name: 'newPath',
        });

        expect(localState.entries.newPath.key).toBe('newPath-blob-newPath');
      });

      it('correctly updates key when renaming an entry in a folder', () => {
        localState.entries['rootFolder/oldPath.md'].key =
          'rootFolder/oldPath.md-blob-rootFolder/oldPath.md';
        mutations.RENAME_ENTRY(localState, {
          path: 'rootFolder/oldPath.md',
          name: 'newPath.md',
          entryPath: null,
          parentPath: 'rootFolder',
        });

        expect(localState.entries['rootFolder/newPath.md'].key).toBe(
          'rootFolder/newPath.md-blob-rootFolder/newPath.md',
        );
      });
    });
  });
});
