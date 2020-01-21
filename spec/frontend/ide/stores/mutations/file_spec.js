import mutations from '~/ide/stores/mutations/file';
import { createStore } from '~/ide/stores';
import { FILE_VIEW_MODE_PREVIEW } from '~/ide/constants';
import { file } from '../../helpers';

describe('IDE store file mutations', () => {
  let localState;
  let localStore;
  let localFile;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
    localFile = { ...file('file'), type: 'blob', content: 'original' };

    localState.entries[localFile.path] = localFile;
  });

  describe('SET_FILE_ACTIVE', () => {
    it('sets the file active', () => {
      mutations.SET_FILE_ACTIVE(localState, {
        path: localFile.path,
        active: true,
      });

      expect(localFile.active).toBeTruthy();
    });

    it('sets pending tab as not active', () => {
      localState.openFiles.push({ ...localFile, pending: true, active: true });

      mutations.SET_FILE_ACTIVE(localState, {
        path: localFile.path,
        active: true,
      });

      expect(localState.openFiles[0].active).toBe(false);
    });
  });

  describe('TOGGLE_FILE_OPEN', () => {
    beforeEach(() => {
      mutations.TOGGLE_FILE_OPEN(localState, localFile.path);
    });

    it('adds into opened files', () => {
      expect(localFile.opened).toBeTruthy();
      expect(localState.openFiles.length).toBe(1);
    });

    it('removes from opened files', () => {
      mutations.TOGGLE_FILE_OPEN(localState, localFile.path);

      expect(localFile.opened).toBeFalsy();
      expect(localState.openFiles.length).toBe(0);
    });
  });

  describe('SET_FILE_DATA', () => {
    it('sets extra file data', () => {
      mutations.SET_FILE_DATA(localState, {
        data: {
          blame_path: 'blame',
          commits_path: 'commits',
          permalink: 'permalink',
          raw_path: 'raw',
          binary: true,
          render_error: 'render_error',
        },
        file: localFile,
      });

      expect(localFile.blamePath).toBe('blame');
      expect(localFile.commitsPath).toBe('commits');
      expect(localFile.permalink).toBe('permalink');
      expect(localFile.rawPath).toBe('raw');
      expect(localFile.binary).toBeTruthy();
      expect(localFile.renderError).toBe('render_error');
      expect(localFile.raw).toBeNull();
      expect(localFile.baseRaw).toBeNull();
    });

    it('sets extra file data to all arrays concerned', () => {
      localState.stagedFiles = [localFile];
      localState.changedFiles = [localFile];
      localState.openFiles = [localFile];

      const rawPath = 'foo/bar/blah.md';

      mutations.SET_FILE_DATA(localState, {
        data: {
          raw_path: rawPath,
        },
        file: localFile,
      });

      expect(localState.stagedFiles[0].rawPath).toEqual(rawPath);
      expect(localState.changedFiles[0].rawPath).toEqual(rawPath);
      expect(localState.openFiles[0].rawPath).toEqual(rawPath);
      expect(localFile.rawPath).toEqual(rawPath);
    });

    it('does not mutate certain props on the file', () => {
      const path = 'New Path';
      const name = 'New Name';
      localFile.path = path;
      localFile.name = name;

      localState.stagedFiles = [localFile];
      localState.changedFiles = [localFile];
      localState.openFiles = [localFile];

      mutations.SET_FILE_DATA(localState, {
        data: {
          path: 'Old Path',
          name: 'Old Name',
          raw: 'Old Raw',
          base_raw: 'Old Base Raw',
        },
        file: localFile,
      });

      [
        localState.stagedFiles[0],
        localState.changedFiles[0],
        localState.openFiles[0],
        localFile,
      ].forEach(f => {
        expect(f).toEqual(
          expect.objectContaining({
            path,
            name,
            raw: null,
            baseRaw: null,
          }),
        );
      });
    });
  });

  describe('SET_FILE_RAW_DATA', () => {
    const callMutationForFile = f => {
      mutations.SET_FILE_RAW_DATA(localState, {
        file: f,
        raw: 'testing',
        fileDeletedAndReadded: localStore.getters.isFileDeletedAndReadded(localFile.path),
      });
    };

    it('sets raw data', () => {
      callMutationForFile(localFile);

      expect(localFile.raw).toBe('testing');
    });

    it('sets raw data to stagedFile if file was deleted and readded', () => {
      localState.stagedFiles = [{ ...localFile, deleted: true }];
      localFile.tempFile = true;

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localState.stagedFiles[0].raw).toBe('testing');
    });

    it("sets raw data to a file's content if tempFile is empty", () => {
      localFile.tempFile = true;
      localFile.content = '';

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localFile.content).toBe('testing');
    });

    it('adds raw data to open pending file', () => {
      localState.openFiles.push({ ...localFile, pending: true });

      callMutationForFile(localFile);

      expect(localState.openFiles[0].raw).toBe('testing');
    });

    it('sets raw to content of a renamed tempFile', () => {
      localFile.tempFile = true;
      localFile.prevPath = 'old_path';
      localState.openFiles.push({ ...localFile, pending: true });

      callMutationForFile(localFile);

      expect(localState.openFiles[0].raw).not.toBe('testing');
      expect(localState.openFiles[0].content).toBe('testing');
    });

    it('adds raw data to a staged deleted file if unstaged change has a tempFile of the same name', () => {
      localFile.tempFile = true;
      localState.openFiles.push({ ...localFile, pending: true });
      localState.stagedFiles = [{ ...localFile, deleted: true }];

      callMutationForFile(localFile);

      expect(localFile.raw).toBeFalsy();
      expect(localState.stagedFiles[0].raw).toBe('testing');
    });
  });

  describe('SET_FILE_BASE_RAW_DATA', () => {
    it('sets raw data from base branch', () => {
      mutations.SET_FILE_BASE_RAW_DATA(localState, {
        file: localFile,
        baseRaw: 'testing',
      });

      expect(localFile.baseRaw).toBe('testing');
    });
  });

  describe('UPDATE_FILE_CONTENT', () => {
    beforeEach(() => {
      localFile.raw = 'test';
    });

    it('sets content', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: 'test',
      });

      expect(localFile.content).toBe('test');
    });

    it('sets changed if content does not match raw', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: 'testing',
      });

      expect(localFile.content).toBe('testing');
      expect(localFile.changed).toBeTruthy();
    });

    it('sets changed if file is a temp file', () => {
      localFile.tempFile = true;

      mutations.UPDATE_FILE_CONTENT(localState, {
        path: localFile.path,
        content: '',
      });

      expect(localFile.changed).toBeTruthy();
    });
  });

  describe('SET_FILE_MERGE_REQUEST_CHANGE', () => {
    it('sets file mr change', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
        },
      });

      expect(localFile.mrChange.diff).toBe('ABC');
    });

    it('has diffMode replaced by default', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
        },
      });

      expect(localFile.mrChange.diffMode).toBe('replaced');
    });

    it('has diffMode new', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          new_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('new');
    });

    it('has diffMode deleted', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          deleted_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('deleted');
    });

    it('has diffMode renamed', () => {
      mutations.SET_FILE_MERGE_REQUEST_CHANGE(localState, {
        file: localFile,
        mrChange: {
          diff: 'ABC',
          renamed_file: true,
        },
      });

      expect(localFile.mrChange.diffMode).toBe('renamed');
    });
  });

  describe('DISCARD_FILE_CHANGES', () => {
    beforeEach(() => {
      localFile.content = 'test';
      localFile.changed = true;
      localState.currentProjectId = 'gitlab-ce';
      localState.currentBranchId = 'master';
      localState.trees['gitlab-ce/master'] = {
        tree: [],
      };
    });

    it('resets content and changed', () => {
      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localFile.content).toBe('');
      expect(localFile.changed).toBeFalsy();
    });

    it('adds to root tree if deleted', () => {
      localFile.deleted = true;

      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localState.trees['gitlab-ce/master'].tree).toEqual([{ ...localFile, deleted: false }]);
    });

    it('adds to parent tree if deleted', () => {
      localFile.deleted = true;
      localFile.parentPath = 'parentPath';
      localState.entries.parentPath = {
        tree: [],
      };

      mutations.DISCARD_FILE_CHANGES(localState, localFile.path);

      expect(localState.entries.parentPath.tree).toEqual([{ ...localFile, deleted: false }]);
    });
  });

  describe('ADD_FILE_TO_CHANGED', () => {
    it('adds file into changed files array', () => {
      mutations.ADD_FILE_TO_CHANGED(localState, localFile.path);

      expect(localState.changedFiles.length).toBe(1);
    });
  });

  describe('REMOVE_FILE_FROM_CHANGED', () => {
    it('removes files from changed files array', () => {
      localState.changedFiles.push(localFile);

      mutations.REMOVE_FILE_FROM_CHANGED(localState, localFile.path);

      expect(localState.changedFiles.length).toBe(0);
    });
  });

  describe.each`
    mutationName        | mutation                    | addedTo           | removedFrom       | staged   | changedFilesCount | stagedFilesCount
    ${'STAGE_CHANGE'}   | ${mutations.STAGE_CHANGE}   | ${'stagedFiles'}  | ${'changedFiles'} | ${true}  | ${0}              | ${1}
    ${'UNSTAGE_CHANGE'} | ${mutations.UNSTAGE_CHANGE} | ${'changedFiles'} | ${'stagedFiles'}  | ${false} | ${1}              | ${0}
  `(
    '$mutationName',
    ({ mutation, changedFilesCount, removedFrom, addedTo, staged, stagedFilesCount }) => {
      let unstagedFile;
      let stagedFile;

      beforeEach(() => {
        unstagedFile = {
          ...file('file'),
          type: 'blob',
          raw: 'original content',
          content: 'changed content',
        };

        stagedFile = {
          ...unstagedFile,
          content: 'staged content',
          staged: true,
        };

        localState.changedFiles.push(unstagedFile);
        localState.stagedFiles.push(stagedFile);
        localState.entries[unstagedFile.path] = unstagedFile;
      });

      it('removes all changes of a file if staged and unstaged change contents are equal', () => {
        unstagedFile.content = 'original content';

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.entries.file).toEqual(
          expect.objectContaining({
            content: 'original content',
            staged: false,
            changed: false,
          }),
        );

        expect(localState.stagedFiles.length).toBe(0);
        expect(localState.changedFiles.length).toBe(0);
      });

      it('removes all changes of a file if a file is deleted and a new file with same content is added', () => {
        stagedFile.deleted = true;
        unstagedFile.tempFile = true;
        unstagedFile.content = 'original content';

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.stagedFiles.length).toBe(0);
        expect(localState.changedFiles.length).toBe(0);

        expect(localState.entries.file).toEqual(
          expect.objectContaining({
            content: 'original content',
            deleted: false,
            tempFile: false,
          }),
        );
      });

      it('merges deleted and added file into a changed file if the contents differ', () => {
        stagedFile.deleted = true;
        unstagedFile.tempFile = true;
        unstagedFile.content = 'hello';

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.stagedFiles.length).toBe(stagedFilesCount);
        expect(localState.changedFiles.length).toBe(changedFilesCount);

        expect(unstagedFile).toEqual(
          expect.objectContaining({
            content: 'hello',
            staged,
            deleted: false,
            tempFile: false,
            changed: true,
          }),
        );
      });

      it('does not remove file from stagedFiles and changedFiles if the file was renamed, even if the contents are equal', () => {
        unstagedFile.content = 'original content';
        unstagedFile.prevPath = 'old_file';

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.entries.file).toEqual(
          expect.objectContaining({
            content: 'original content',
            staged,
            changed: false,
            prevPath: 'old_file',
          }),
        );

        expect(localState.stagedFiles.length).toBe(stagedFilesCount);
        expect(localState.changedFiles.length).toBe(changedFilesCount);
      });

      it(`removes file from ${removedFrom} array and adds it into ${addedTo} array`, () => {
        localState.stagedFiles.length = 0;

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.stagedFiles.length).toBe(stagedFilesCount);
        expect(localState.changedFiles.length).toBe(changedFilesCount);

        const f = localState.stagedFiles[0] || localState.changedFiles[0];
        expect(f).toEqual(unstagedFile);
      });

      it(`updates file in ${addedTo} array if it is was already present in it`, () => {
        unstagedFile.raw = 'testing 123';

        mutation(localState, {
          path: unstagedFile.path,
          diffInfo: localStore.getters.getDiffInfo(unstagedFile.path),
        });

        expect(localState.stagedFiles.length).toBe(stagedFilesCount);
        expect(localState.changedFiles.length).toBe(changedFilesCount);

        const f = localState.stagedFiles[0] || localState.changedFiles[0];
        expect(f.raw).toEqual('testing 123');
      });
    },
  );

  describe('TOGGLE_FILE_CHANGED', () => {
    it('updates file changed status', () => {
      mutations.TOGGLE_FILE_CHANGED(localState, {
        file: localFile,
        changed: true,
      });

      expect(localFile.changed).toBeTruthy();
    });
  });

  describe('SET_FILE_VIEWMODE', () => {
    it('updates file view mode', () => {
      mutations.SET_FILE_VIEWMODE(localState, {
        file: localFile,
        viewMode: FILE_VIEW_MODE_PREVIEW,
      });

      expect(localFile.viewMode).toBe(FILE_VIEW_MODE_PREVIEW);
    });
  });

  describe('ADD_PENDING_TAB', () => {
    beforeEach(() => {
      const f = { ...file('openFile'), path: 'openFile', active: true, opened: true };

      localState.entries[f.path] = f;
      localState.openFiles.push(f);
    });

    it('adds file into openFiles as pending', () => {
      mutations.ADD_PENDING_TAB(localState, {
        file: localFile,
      });

      expect(localState.openFiles.length).toBe(1);
      expect(localState.openFiles[0].pending).toBe(true);
      expect(localState.openFiles[0].key).toBe(`pending-${localFile.key}`);
    });

    it('only allows 1 open pending file', () => {
      const newFile = file('test');
      localState.entries[newFile.path] = newFile;

      mutations.ADD_PENDING_TAB(localState, {
        file: localFile,
      });

      expect(localState.openFiles.length).toBe(1);

      mutations.ADD_PENDING_TAB(localState, {
        file: file('test'),
      });

      expect(localState.openFiles.length).toBe(1);
      expect(localState.openFiles[0].name).toBe('test');
    });
  });

  describe('REMOVE_PENDING_TAB', () => {
    it('removes pending tab from openFiles', () => {
      localFile.key = 'testing';
      localState.openFiles.push(localFile);

      mutations.REMOVE_PENDING_TAB(localState, localFile);

      expect(localState.openFiles.length).toBe(0);
    });
  });
});
