import MockAdapter from 'axios-mock-adapter';
import { stubPerformanceWebAPI } from 'helpers/performance';
import testAction from 'helpers/vuex_action_helper';
import eventHub from '~/ide/eventhub';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';
import { createAlert } from '~/alert';
import {
  init,
  stageAllChanges,
  unstageAllChanges,
  toggleFileFinder,
  setCurrentBranchId,
  setEmptyStateSvgs,
  updateActivityBarView,
  updateTempFlagForEntry,
  setErrorMessage,
  deleteEntry,
  renameEntry,
  getBranchData,
  createTempEntry,
  discardAllChanges,
} from '~/ide/stores/actions';
import * as types from '~/ide/stores/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_IM_A_TEAPOT, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { file, createTriggerRenameAction, createTriggerChangeAction } from '../helpers';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));
jest.mock('~/alert');

describe('Multi-file store actions', () => {
  let store;
  let router;

  beforeEach(() => {
    stubPerformanceWebAPI();

    store = createStore();
    router = createRouter(store);

    jest.spyOn(store, 'commit');
    jest.spyOn(store, 'dispatch');
    jest.spyOn(router, 'push').mockImplementation();
  });

  describe('redirectToUrl', () => {
    it('calls visitUrl', async () => {
      await store.dispatch('redirectToUrl', 'test');
      expect(visitUrl).toHaveBeenCalledWith('test');
    });
  });

  describe('init', () => {
    it('commits initial data and requests user callouts', () => {
      return testAction(
        init,
        { canCommit: true },
        store.state,
        [{ type: 'SET_INITIAL_DATA', payload: { canCommit: true } }],
        [],
      );
    });
  });

  describe('discardAllChanges', () => {
    const paths = ['to_discard', 'another_one_to_discard'];

    beforeEach(() => {
      paths.forEach((path) => {
        const f = file(path);
        f.changed = true;

        store.state.openFiles.push(f);
        store.state.changedFiles.push(f);
        store.state.entries[f.path] = f;
      });
    });

    it('discards all changes in file', () => {
      const expectedCalls = paths.map((path) => ['restoreOriginalFile', path]);

      discardAllChanges(store);

      expect(store.dispatch.mock.calls).toEqual(expect.arrayContaining(expectedCalls));
    });

    it('removes all files from changedFiles state', async () => {
      await store.dispatch('discardAllChanges');
      expect(store.state.changedFiles.length).toBe(0);
      expect(store.state.openFiles.length).toBe(2);
    });
  });

  describe('createTempEntry', () => {
    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"></div>';

      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'mybranch';

      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };
      store.state.projects.abcproject = {
        web_url: '',
      };
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    describe('tree', () => {
      it('creates temp tree', async () => {
        await store.dispatch('createTempEntry', {
          name: 'test',
          type: 'tree',
        });
        const entry = store.state.entries.test;

        expect(entry).not.toBeNull();
        expect(entry.type).toBe('tree');
      });

      it('creates new folder inside another tree', async () => {
        const tree = {
          type: 'tree',
          name: 'testing',
          path: 'testing',
          tree: [],
        };

        store.state.entries[tree.path] = tree;

        await store.dispatch('createTempEntry', {
          name: 'testing/test',
          type: 'tree',
        });
        expect(tree.tree[0].tempFile).toBe(true);
        expect(tree.tree[0].name).toBe('test');
        expect(tree.tree[0].type).toBe('tree');
      });

      it('does not create new tree if already exists', async () => {
        const tree = {
          type: 'tree',
          path: 'testing',
          tempFile: false,
          tree: [],
        };

        store.state.entries[tree.path] = tree;

        await store.dispatch('createTempEntry', {
          name: 'testing',
          type: 'tree',
        });
        expect(store.state.entries[tree.path].tempFile).toEqual(false);
        expect(createAlert).toHaveBeenCalled();
      });
    });

    describe('blob', () => {
      it('creates temp file', async () => {
        const name = 'test';

        await store.dispatch('createTempEntry', {
          name,
          type: 'blob',
          mimeType: 'test/mime',
        });
        const f = store.state.entries[name];

        expect(f.tempFile).toBe(true);
        expect(f.mimeType).toBe('test/mime');
        expect(store.state.trees['abcproject/mybranch'].tree.length).toBe(1);
      });

      it('adds tmp file to open files', async () => {
        const name = 'test';

        await store.dispatch('createTempEntry', {
          name,
          type: 'blob',
        });
        const f = store.state.entries[name];

        expect(store.state.openFiles.length).toBe(1);
        expect(store.state.openFiles[0].name).toBe(f.name);
      });

      it('adds tmp file to staged files', async () => {
        const name = 'test';

        await store.dispatch('createTempEntry', {
          name,
          type: 'blob',
        });
        expect(store.state.stagedFiles).toEqual([expect.objectContaining({ name })]);
      });

      it('sets tmp file as active', () => {
        createTempEntry(store, { name: 'test', type: 'blob' });

        expect(store.dispatch).toHaveBeenCalledWith('setFileActive', 'test');
      });

      it('creates alert if file already exists', async () => {
        const f = file('test', '1', 'blob');
        store.state.trees['abcproject/mybranch'].tree = [f];
        store.state.entries[f.path] = f;

        await store.dispatch('createTempEntry', {
          name: 'test',
          type: 'blob',
        });
        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: `The name "${f.name}" is already taken in this directory.`,
          }),
        );
      });
    });
  });

  describe('scrollToTab', () => {
    it('focuses the current active element', () => {
      document.body.innerHTML +=
        '<div id="tabs"><div class="active"><div class="repo-tab"></div></div></div>';
      const el = document.querySelector('.repo-tab');
      jest.spyOn(el, 'focus').mockImplementation();

      return store.dispatch('scrollToTab').then(() => {
        expect(el.focus).toHaveBeenCalled();

        document.getElementById('tabs').remove();
      });
    });
  });

  describe('stage/unstageAllChanges', () => {
    let file1;
    let file2;

    beforeEach(() => {
      file1 = { ...file('test'), content: 'changed test', raw: 'test' };
      file2 = { ...file('test2'), content: 'changed test2', raw: 'test2' };

      store.state.openFiles = [file1];
      store.state.changedFiles = [file1];
      store.state.stagedFiles = [{ ...file2, content: 'staged test' }];

      store.state.entries = {
        [file1.path]: { ...file1 },
        [file2.path]: { ...file2 },
      };
    });

    describe('stageAllChanges', () => {
      it('adds all files from changedFiles to stagedFiles', () => {
        stageAllChanges(store);

        expect(store.commit.mock.calls).toEqual(
          expect.arrayContaining([
            [types.SET_LAST_COMMIT_MSG, ''],
            [types.STAGE_CHANGE, expect.objectContaining({ path: file1.path })],
          ]),
        );
      });

      it('opens pending tab if a change exists in that file', () => {
        stageAllChanges(store);

        expect(store.dispatch.mock.calls).toEqual([
          [
            'openPendingTab',
            { file: { ...file1, staged: true, changed: true }, keyPrefix: 'staged' },
          ],
        ]);
      });

      it('does not open pending tab if no change exists in that file', () => {
        store.state.entries[file1.path].content = 'test';
        store.state.stagedFiles = [file1];
        store.state.changedFiles = [store.state.entries[file1.path]];

        stageAllChanges(store);

        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });

    describe('unstageAllChanges', () => {
      it('removes all files from stagedFiles after unstaging', () => {
        unstageAllChanges(store);

        expect(store.commit.mock.calls).toEqual(
          expect.arrayContaining([
            [types.UNSTAGE_CHANGE, expect.objectContaining({ path: file2.path })],
          ]),
        );
      });

      it('opens pending tab if a change exists in that file', () => {
        unstageAllChanges(store);

        expect(store.dispatch.mock.calls).toEqual([
          ['openPendingTab', { file: file1, keyPrefix: 'unstaged' }],
        ]);
      });

      it('does not open pending tab if no change exists in that file', () => {
        store.state.entries[file1.path].content = 'test';
        store.state.stagedFiles = [file1];
        store.state.changedFiles = [store.state.entries[file1.path]];

        unstageAllChanges(store);

        expect(store.dispatch).not.toHaveBeenCalled();
      });
    });
  });

  describe('updateViewer', () => {
    it('updates viewer state', async () => {
      await store.dispatch('updateViewer', 'diff');
      expect(store.state.viewer).toBe('diff');
    });
  });

  describe('updateActivityBarView', () => {
    it('commits UPDATE_ACTIVITY_BAR_VIEW', () => {
      return testAction(
        updateActivityBarView,
        'test',
        {},
        [{ type: 'UPDATE_ACTIVITY_BAR_VIEW', payload: 'test' }],
        [],
      );
    });
  });

  describe('setEmptyStateSvgs', () => {
    it('commits setEmptyStateSvgs', () => {
      return testAction(
        setEmptyStateSvgs,
        'svg',
        {},
        [{ type: 'SET_EMPTY_STATE_SVGS', payload: 'svg' }],
        [],
      );
    });
  });

  describe('updateTempFlagForEntry', () => {
    it('commits UPDATE_TEMP_FLAG', () => {
      const f = {
        ...file(),
        path: 'test',
        tempFile: true,
      };
      store.state.entries[f.path] = f;

      return testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [],
      );
    });

    it('commits UPDATE_TEMP_FLAG and dispatches for parent', () => {
      const parent = {
        ...file(),
        path: 'testing',
      };
      const f = {
        ...file(),
        path: 'test',
        parentPath: 'testing',
      };
      store.state.entries[parent.path] = parent;
      store.state.entries[f.path] = f;

      return testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [{ type: 'updateTempFlagForEntry', payload: { file: parent, tempFile: false } }],
      );
    });

    it('does not dispatch for parent, if parent does not exist', () => {
      const f = {
        ...file(),
        path: 'test',
        parentPath: 'testing',
      };
      store.state.entries[f.path] = f;

      return testAction(
        updateTempFlagForEntry,
        { file: f, tempFile: false },
        store.state,
        [{ type: 'UPDATE_TEMP_FLAG', payload: { path: f.path, tempFile: false } }],
        [],
      );
    });
  });

  describe('setCurrentBranchId', () => {
    it('commits setCurrentBranchId', () => {
      return testAction(
        setCurrentBranchId,
        'branchId',
        {},
        [{ type: 'SET_CURRENT_BRANCH', payload: 'branchId' }],
        [],
      );
    });
  });

  describe('toggleFileFinder', () => {
    it('commits TOGGLE_FILE_FINDER', () => {
      return testAction(
        toggleFileFinder,
        true,
        null,
        [{ type: 'TOGGLE_FILE_FINDER', payload: true }],
        [],
      );
    });
  });

  describe('setErrorMessage', () => {
    it('commis error message', () => {
      return testAction(
        setErrorMessage,
        'error',
        null,
        [{ type: types.SET_ERROR_MESSAGE, payload: 'error' }],
        [],
      );
    });
  });

  describe('deleteEntry', () => {
    it('commits entry deletion', () => {
      store.state.entries.path = 'testing';

      return testAction(
        deleteEntry,
        'path',
        store.state,
        [{ type: types.DELETE_ENTRY, payload: 'path' }],
        [{ type: 'stageChange', payload: 'path' }, createTriggerChangeAction()],
      );
    });

    it('does not delete a folder after it is emptied', () => {
      const testFolder = {
        type: 'tree',
        tree: [],
      };
      const testEntry = {
        path: 'testFolder/entry-to-delete',
        parentPath: 'testFolder',
        opened: false,
        tree: [],
      };
      testFolder.tree.push(testEntry);
      store.state.entries = {
        testFolder,
        'testFolder/entry-to-delete': testEntry,
      };

      return testAction(
        deleteEntry,
        'testFolder/entry-to-delete',
        store.state,
        [{ type: types.DELETE_ENTRY, payload: 'testFolder/entry-to-delete' }],
        [
          { type: 'stageChange', payload: 'testFolder/entry-to-delete' },
          createTriggerChangeAction(),
        ],
      );
    });

    describe('when renamed', () => {
      let testEntry;

      beforeEach(() => {
        testEntry = {
          path: 'test',
          name: 'test',
          prevPath: 'test_old',
          prevName: 'test_old',
          prevParentPath: '',
        };

        store.state.entries = { test: testEntry };
      });

      describe('and previous does not exist', () => {
        it('reverts the rename before deleting', () => {
          return testAction(
            deleteEntry,
            testEntry.path,
            store.state,
            [],
            [
              {
                type: 'renameEntry',
                payload: {
                  path: testEntry.path,
                  name: testEntry.prevName,
                  parentPath: testEntry.prevParentPath,
                },
              },
              {
                type: 'deleteEntry',
                payload: testEntry.prevPath,
              },
            ],
          );
        });
      });

      describe('and previous exists', () => {
        beforeEach(() => {
          const oldEntry = {
            path: testEntry.prevPath,
            name: testEntry.prevName,
          };

          store.state.entries[oldEntry.path] = oldEntry;
        });

        it('does not revert rename before deleting', () => {
          return testAction(
            deleteEntry,
            testEntry.path,
            store.state,
            [{ type: types.DELETE_ENTRY, payload: testEntry.path }],
            [{ type: 'stageChange', payload: testEntry.path }, createTriggerChangeAction()],
          );
        });

        it('when previous is deleted, it reverts rename before deleting', () => {
          store.state.entries[testEntry.prevPath].deleted = true;

          return testAction(
            deleteEntry,
            testEntry.path,
            store.state,
            [],
            [
              {
                type: 'renameEntry',
                payload: {
                  path: testEntry.path,
                  name: testEntry.prevName,
                  parentPath: testEntry.prevParentPath,
                },
              },
              {
                type: 'deleteEntry',
                payload: testEntry.prevPath,
              },
            ],
          );
        });
      });
    });
  });

  describe('renameEntry', () => {
    describe('purging of file model cache', () => {
      beforeEach(() => {
        jest.spyOn(eventHub, '$emit').mockImplementation();
      });

      it('does not purge model cache for temporary entries that got renamed', async () => {
        Object.assign(store.state.entries, {
          test: {
            ...file('test'),
            key: 'foo-key',
            type: 'blob',
            tempFile: true,
          },
        });

        await store.dispatch('renameEntry', {
          path: 'test',
          name: 'new',
        });
        expect(eventHub.$emit.mock.calls).not.toContain('editor.update.model.dispose.foo-bar');
      });

      it('purges model cache for renamed entry', async () => {
        Object.assign(store.state.entries, {
          test: {
            ...file('test'),
            key: 'foo-key',
            type: 'blob',
            tempFile: false,
          },
        });

        await store.dispatch('renameEntry', {
          path: 'test',
          name: 'new',
        });
        expect(eventHub.$emit).toHaveBeenCalled();
        expect(eventHub.$emit).toHaveBeenCalledWith(`editor.update.model.dispose.foo-key`);
      });
    });

    describe('single entry', () => {
      let origEntry;
      let renamedEntry;

      beforeEach(() => {
        // Need to insert both because `testAction` doesn't actually call the mutation
        origEntry = file('orig', 'orig', 'blob');
        renamedEntry = {
          ...file('renamed', 'renamed', 'blob'),
          prevKey: origEntry.key,
          prevName: origEntry.name,
          prevPath: origEntry.path,
        };

        Object.assign(store.state.entries, {
          orig: origEntry,
          renamed: renamedEntry,
        });
      });

      it('by default renames an entry and stages it', () => {
        const dispatch = jest.fn();
        const commit = jest.fn();

        renameEntry(
          { dispatch, commit, state: store.state, getters: store.getters },
          { path: 'orig', name: 'renamed' },
        );

        expect(commit.mock.calls).toEqual([
          [types.RENAME_ENTRY, { path: 'orig', name: 'renamed', parentPath: undefined }],
          [types.STAGE_CHANGE, expect.objectContaining({ path: 'renamed' })],
        ]);
      });

      it('if not changed, completely unstages and discards entry if renamed to original', () => {
        return testAction(
          renameEntry,
          { path: 'renamed', name: 'orig' },
          store.state,
          [
            {
              type: types.RENAME_ENTRY,
              payload: {
                path: 'renamed',
                name: 'orig',
                parentPath: undefined,
              },
            },
            {
              type: types.REMOVE_FILE_FROM_STAGED_AND_CHANGED,
              payload: origEntry,
            },
          ],
          [createTriggerRenameAction('renamed', 'orig')],
        );
      });

      it('if already in changed, does not add to change', () => {
        store.state.changedFiles.push(renamedEntry);

        return testAction(
          renameEntry,
          { path: 'orig', name: 'renamed' },
          store.state,
          [expect.objectContaining({ type: types.RENAME_ENTRY })],
          [createTriggerRenameAction('orig', 'renamed')],
        );
      });

      it('routes to the renamed file if the original file has been opened', async () => {
        store.state.currentProjectId = 'test/test';
        store.state.currentBranchId = 'main';

        Object.assign(store.state.entries.orig, {
          opened: true,
        });

        await store.dispatch('renameEntry', {
          path: 'orig',
          name: 'renamed',
        });
        expect(router.push.mock.calls).toHaveLength(1);
        expect(router.push).toHaveBeenCalledWith(`/project/test/test/tree/main/-/renamed/`);
      });
    });

    describe('folder', () => {
      let folder;
      let file1;
      let file2;

      beforeEach(() => {
        folder = file('folder', 'folder', 'tree');
        file1 = file('file-1', 'file-1', 'blob', folder);
        file2 = file('file-2', 'file-2', 'blob', folder);

        folder.tree = [file1, file2];

        Object.assign(store.state.entries, {
          [folder.path]: folder,
          [file1.path]: file1,
          [file2.path]: file2,
        });
      });

      it('updates entries in a folder correctly, when folder is renamed', async () => {
        await store.dispatch('renameEntry', {
          path: 'folder',
          name: 'new-folder',
        });
        const keys = Object.keys(store.state.entries);

        expect(keys.length).toBe(3);
        expect(keys.indexOf('new-folder')).toBe(0);
        expect(keys.indexOf('new-folder/file-1')).toBe(1);
        expect(keys.indexOf('new-folder/file-2')).toBe(2);
      });

      it('discards renaming of an entry if the root folder is renamed back to a previous name', async () => {
        const rootFolder = file('old-folder', 'old-folder', 'tree');
        const testEntry = file('test', 'test', 'blob', rootFolder);

        Object.assign(store.state, {
          entries: {
            'old-folder': {
              ...rootFolder,
              tree: [testEntry],
            },
            'old-folder/test': testEntry,
          },
        });

        await store.dispatch('renameEntry', {
          path: 'old-folder',
          name: 'new-folder',
        });
        const { entries } = store.state;

        expect(Object.keys(entries).length).toBe(2);
        expect(entries['old-folder']).toBeUndefined();
        expect(entries['old-folder/test']).toBeUndefined();

        expect(entries['new-folder']).toBeDefined();
        expect(entries['new-folder/test']).toEqual(
          expect.objectContaining({
            path: 'new-folder/test',
            name: 'test',
            prevPath: 'old-folder/test',
            prevName: 'test',
          }),
        );

        await store.dispatch('renameEntry', {
          path: 'new-folder',
          name: 'old-folder',
        });
        const { entries: newEntries } = store.state;

        expect(Object.keys(newEntries).length).toBe(2);
        expect(newEntries['new-folder']).toBeUndefined();
        expect(newEntries['new-folder/test']).toBeUndefined();

        expect(newEntries['old-folder']).toBeDefined();
        expect(newEntries['old-folder/test']).toEqual(
          expect.objectContaining({
            path: 'old-folder/test',
            name: 'test',
            prevPath: undefined,
            prevName: undefined,
          }),
        );
      });

      describe('with file in directory', () => {
        const parentPath = 'original-dir';
        const newParentPath = 'new-dir';
        const fileName = 'test.md';
        const filePath = `${parentPath}/${fileName}`;

        let rootDir;

        beforeEach(() => {
          const parentEntry = file(parentPath, parentPath, 'tree');
          const fileEntry = file(filePath, filePath, 'blob', parentEntry);
          rootDir = {
            tree: [],
          };

          Object.assign(store.state, {
            entries: {
              [parentPath]: {
                ...parentEntry,
                tree: [fileEntry],
              },
              [filePath]: fileEntry,
            },
            trees: {
              '/': rootDir,
            },
          });
        });

        it('creates new directory', async () => {
          expect(store.state.entries[newParentPath]).toBeUndefined();

          await store.dispatch('renameEntry', {
            path: filePath,
            name: fileName,
            parentPath: newParentPath,
          });
          expect(store.state.entries[newParentPath]).toEqual(
            expect.objectContaining({
              path: newParentPath,
              type: 'tree',
              tree: expect.arrayContaining([store.state.entries[`${newParentPath}/${fileName}`]]),
            }),
          );
        });

        describe('when new directory exists', () => {
          let newDir;

          beforeEach(() => {
            newDir = file(newParentPath, newParentPath, 'tree');

            store.state.entries[newDir.path] = newDir;
            rootDir.tree.push(newDir);
          });

          it('inserts in new directory', async () => {
            expect(newDir.tree).toEqual([]);

            await store.dispatch('renameEntry', {
              path: filePath,
              name: fileName,
              parentPath: newParentPath,
            });
            expect(newDir.tree).toEqual([store.state.entries[`${newParentPath}/${fileName}`]]);
          });

          it('when new directory is deleted, it undeletes it', async () => {
            await store.dispatch('deleteEntry', newParentPath);

            expect(store.state.entries[newParentPath].deleted).toBe(true);
            expect(rootDir.tree.some((x) => x.path === newParentPath)).toBe(false);

            await store.dispatch('renameEntry', {
              path: filePath,
              name: fileName,
              parentPath: newParentPath,
            });
            expect(store.state.entries[newParentPath].deleted).toBe(false);
            expect(rootDir.tree.some((x) => x.path === newParentPath)).toBe(true);
          });
        });
      });
    });
  });

  describe('getBranchData', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('error', () => {
      let dispatch;
      let callParams;

      beforeEach(() => {
        callParams = [
          {
            commit() {},
            state: store.state,
          },
          {
            projectId: 'abc/def',
            branchId: 'main-testing',
          },
        ];
        dispatch = jest.fn();
        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        document.querySelector('.flash-container').remove();
      });

      it('passes the error further unchanged without dispatching any action when response is 404', async () => {
        mock.onGet(/(.*)/).replyOnce(HTTP_STATUS_NOT_FOUND);

        await expect(getBranchData(...callParams)).rejects.toEqual(
          new Error('Request failed with status code 404'),
        );
        expect(dispatch.mock.calls).toHaveLength(0);
        expect(document.querySelector('.flash-alert')).toBeNull();
      });

      it('does not pass the error further and creates an alert if error is not 404', async () => {
        mock.onGet(/(.*)/).replyOnce(HTTP_STATUS_IM_A_TEAPOT);

        await expect(getBranchData(...callParams)).rejects.toEqual(
          new Error('Branch not loaded - <strong>abc/def/main-testing</strong>'),
        );

        expect(dispatch.mock.calls).toHaveLength(0);
        expect(createAlert).toHaveBeenCalled();
      });
    });
  });
});
