import mutations from '~/ide/stores/mutations/file';
import state from '~/ide/stores/state';
import { FILE_VIEW_MODE_PREVIEW } from '~/ide/constants';
import { file } from '../../helpers';

describe('IDE store file mutations', () => {
  let localState;
  let localFile;

  beforeEach(() => {
    localState = state();
    localFile = { ...file(), type: 'blob' };

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
    it('sets raw data', () => {
      mutations.SET_FILE_RAW_DATA(localState, {
        file: localFile,
        raw: 'testing',
      });

      expect(localFile.raw).toBe('testing');
    });

    it('adds raw data to open pending file', () => {
      localState.openFiles.push({ ...localFile, pending: true });

      mutations.SET_FILE_RAW_DATA(localState, {
        file: localFile,
        raw: 'testing',
      });

      expect(localState.openFiles[0].raw).toBe('testing');
    });

    it('does not add raw data to open pending tempFile file', () => {
      localState.openFiles.push({ ...localFile, pending: true, tempFile: true });

      mutations.SET_FILE_RAW_DATA(localState, {
        file: localFile,
        raw: 'testing',
      });

      expect(localState.openFiles[0].raw).not.toBe('testing');
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

  describe('STAGE_CHANGE', () => {
    beforeEach(() => {
      mutations.STAGE_CHANGE(localState, localFile.path);
    });

    it('adds file into stagedFiles array', () => {
      expect(localState.stagedFiles.length).toBe(1);
      expect(localState.stagedFiles[0]).toEqual(localFile);
    });

    it('updates stagedFile if it is already staged', () => {
      localFile.raw = 'testing 123';

      mutations.STAGE_CHANGE(localState, localFile.path);

      expect(localState.stagedFiles.length).toBe(1);
      expect(localState.stagedFiles[0].raw).toEqual('testing 123');
    });
  });

  describe('UNSTAGE_CHANGE', () => {
    let f;

    beforeEach(() => {
      f = { ...file(), type: 'blob', staged: true };

      localState.stagedFiles.push(f);
      localState.changedFiles.push(f);
      localState.entries[f.path] = f;
    });

    it('removes from stagedFiles array', () => {
      mutations.UNSTAGE_CHANGE(localState, f.path);

      expect(localState.stagedFiles.length).toBe(0);
      expect(localState.changedFiles.length).toBe(1);
    });
  });

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
