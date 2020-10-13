import { TEST_HOST } from 'helpers/test_constants';
import * as getters from '~/ide/stores/getters';
import { createStore } from '~/ide/stores';
import { file } from '../helpers';

const TEST_PROJECT_ID = 'test_project';

describe('IDE store getters', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('activeFile', () => {
    it('returns the current active file', () => {
      localState.openFiles.push(file());
      localState.openFiles.push(file('active'));
      localState.openFiles[1].active = true;

      expect(getters.activeFile(localState).name).toBe('active');
    });

    it('returns undefined if no active files are found', () => {
      localState.openFiles.push(file());
      localState.openFiles.push(file('active'));

      expect(getters.activeFile(localState)).toBeNull();
    });
  });

  describe('modifiedFiles', () => {
    it('returns a list of modified files', () => {
      localState.openFiles.push(file());
      localState.changedFiles.push(file('changed'));
      localState.changedFiles[0].changed = true;

      const modifiedFiles = getters.modifiedFiles(localState);

      expect(modifiedFiles.length).toBe(1);
      expect(modifiedFiles[0].name).toBe('changed');
    });
  });

  describe('currentMergeRequest', () => {
    it('returns Current Merge Request', () => {
      localState.currentProjectId = 'abcproject';
      localState.currentMergeRequestId = 1;
      localState.projects.abcproject = {
        mergeRequests: {
          1: {
            mergeId: 1,
          },
        },
      };

      expect(getters.currentMergeRequest(localState).mergeId).toBe(1);
    });

    it('returns null if no active Merge Request was found', () => {
      localState.currentProjectId = 'otherproject';

      expect(getters.currentMergeRequest(localState)).toBeNull();
    });
  });

  describe('allBlobs', () => {
    beforeEach(() => {
      Object.assign(localState.entries, {
        index: {
          type: 'blob',
          name: 'index',
          lastOpenedAt: 0,
        },
        app: {
          type: 'blob',
          name: 'blob',
          lastOpenedAt: 0,
        },
        folder: {
          type: 'folder',
          name: 'folder',
          lastOpenedAt: 0,
        },
      });
    });

    it('returns only blobs', () => {
      expect(getters.allBlobs(localState).length).toBe(2);
    });

    it('returns list sorted by lastOpenedAt', () => {
      localState.entries.app.lastOpenedAt = new Date().getTime();

      expect(getters.allBlobs(localState)[0].name).toBe('blob');
    });
  });

  describe('getChangesInFolder', () => {
    it('returns length of changed files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'app/123',
          name: '123',
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(1);
    });

    it('returns length of changed & staged files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'testing/123',
          name: '123',
        },
      );

      localState.stagedFiles.push(
        {
          path: 'test/123',
          name: '123',
        },
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'testing/12345',
          name: '12345',
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(2);
    });

    it('returns length of changed & tempFiles files for a path', () => {
      localState.changedFiles.push(
        {
          path: 'test/index',
          name: 'index',
        },
        {
          path: 'test/newfile',
          name: 'newfile',
          tempFile: true,
        },
      );

      expect(getters.getChangesInFolder(localState)('test')).toBe(2);
    });
  });

  describe('lastCommit', () => {
    it('returns the last commit of the current branch on the current project', () => {
      const commitTitle = 'Example commit title';
      const localGetters = {
        currentProject: {
          name: 'test-project',
        },
        currentBranch: {
          commit: {
            title: commitTitle,
          },
        },
      };
      localState.currentBranchId = 'example-branch';

      expect(getters.lastCommit(localState, localGetters).title).toBe(commitTitle);
    });
  });

  describe('currentBranch', () => {
    it('returns current projects branch', () => {
      localState.currentProjectId = 'abcproject';
      localState.currentBranchId = 'master';
      localState.projects.abcproject = {
        name: 'abcproject',
        branches: {
          master: {
            name: 'master',
          },
        },
      };
      const localGetters = {
        findBranch: jest.fn(),
      };
      getters.currentBranch(localState, localGetters);

      expect(localGetters.findBranch).toHaveBeenCalledWith('abcproject', 'master');
    });
  });

  describe('findProject', () => {
    it('returns the project matching the id', () => {
      localState.currentProjectId = 'abcproject';
      localState.projects.abcproject = {
        name: 'abcproject',
      };

      expect(getters.findProject(localState)('abcproject').name).toBe('abcproject');
    });
  });

  describe('findBranch', () => {
    let result;

    it('returns the selected branch from a project', () => {
      localState.currentProjectId = 'abcproject';
      localState.currentBranchId = 'master';
      localState.projects.abcproject = {
        name: 'abcproject',
        branches: {
          master: {
            name: 'master',
          },
        },
      };
      const localGetters = {
        findProject: () => localState.projects.abcproject,
      };

      result = getters.findBranch(localState, localGetters)('abcproject', 'master');

      expect(result.name).toBe('master');
    });
  });

  describe('isOnDefaultBranch', () => {
    it('returns false when no project exists', () => {
      const localGetters = {
        currentProject: undefined,
      };

      expect(getters.isOnDefaultBranch({}, localGetters)).toBeFalsy();
    });

    it("returns true when project's default branch matches current branch", () => {
      const localGetters = {
        currentProject: {
          default_branch: 'master',
        },
        branchName: 'master',
      };

      expect(getters.isOnDefaultBranch({}, localGetters)).toBeTruthy();
    });

    it("returns false when project's default branch doesn't match current branch", () => {
      const localGetters = {
        currentProject: {
          default_branch: 'master',
        },
        branchName: 'feature',
      };

      expect(getters.isOnDefaultBranch({}, localGetters)).toBeFalsy();
    });
  });

  describe('packageJson', () => {
    it('returns package.json entry', () => {
      localState.entries['package.json'] = {
        name: 'package.json',
      };

      expect(getters.packageJson(localState)).toEqual({
        name: 'package.json',
      });
    });
  });

  describe('canPushToBranch', () => {
    it.each`
      currentBranch          | canPushCode  | expectedValue
      ${undefined}           | ${undefined} | ${false}
      ${{ can_push: true }}  | ${false}     | ${true}
      ${{ can_push: true }}  | ${true}      | ${true}
      ${{ can_push: false }} | ${false}     | ${false}
      ${{ can_push: false }} | ${true}      | ${false}
      ${undefined}           | ${true}      | ${true}
      ${undefined}           | ${false}     | ${false}
    `(
      'with currentBranch ($currentBranch) and canPushCode ($canPushCode), it is $expectedValue',
      ({ currentBranch, canPushCode, expectedValue }) => {
        expect(getters.canPushToBranch({}, { currentBranch, canPushCode })).toBe(expectedValue);
      },
    );
  });

  describe('isFileDeletedAndReadded', () => {
    const f = { ...file('sample'), content: 'sample', raw: 'sample' };

    it.each([
      {
        entry: { ...f, tempFile: true },
        staged: { ...f, deleted: true },
        output: true,
      },
      {
        entry: { ...f, content: 'changed' },
        staged: { ...f, content: 'changed' },
        output: false,
      },
      {
        entry: { ...f, content: 'changed' },
        output: false,
      },
    ])(
      'checks staged and unstaged files to see if a file was deleted and readded (case %#)',
      ({ entry, staged, output }) => {
        Object.assign(localState, {
          entries: {
            [entry.path]: entry,
          },
          stagedFiles: [],
        });

        if (staged) localState.stagedFiles.push(staged);

        expect(localStore.getters.isFileDeletedAndReadded(entry.path)).toBe(output);
      },
    );
  });

  describe('getDiffInfo', () => {
    const f = { ...file('sample'), content: 'sample', raw: 'sample' };
    it.each([
      {
        entry: { ...f, tempFile: true },
        staged: { ...f, deleted: true },
        output: { deleted: false, changed: false, tempFile: false },
      },
      {
        entry: { ...f, tempFile: true, content: 'changed', raw: '' },
        staged: { ...f, deleted: true },
        output: { deleted: false, changed: true, tempFile: false },
      },
      {
        entry: { ...f, content: 'changed' },
        output: { changed: true },
      },
      {
        entry: { ...f, content: 'sample' },
        staged: { ...f, content: 'changed' },
        output: { changed: false },
      },
      {
        entry: { ...f, deleted: true },
        output: { deleted: true, changed: false },
      },
      {
        entry: { ...f, prevPath: 'old_path' },
        output: { renamed: true, changed: false },
      },
      {
        entry: { ...f, prevPath: 'old_path', content: 'changed' },
        output: { renamed: true, changed: true },
      },
    ])(
      'compares changes in a file entry and returns a resulting diff info (case %#)',
      ({ entry, staged, output }) => {
        Object.assign(localState, {
          entries: {
            [entry.path]: entry,
          },
          stagedFiles: [],
        });

        if (staged) localState.stagedFiles.push(staged);

        expect(localStore.getters.getDiffInfo(entry.path)).toEqual(expect.objectContaining(output));
      },
    );
  });

  describe('findProjectPermissions', () => {
    it('returns false if project not found', () => {
      expect(localStore.getters.findProjectPermissions(TEST_PROJECT_ID)).toEqual({});
    });

    it('finds permission in given project', () => {
      const userPermissions = {
        readMergeRequest: true,
        createMergeRequestsIn: false,
      };

      localState.projects[TEST_PROJECT_ID] = { userPermissions };

      expect(localStore.getters.findProjectPermissions(TEST_PROJECT_ID)).toBe(userPermissions);
    });
  });

  describe.each`
    getterName                  | permissionKey
    ${'canReadMergeRequests'}   | ${'readMergeRequest'}
    ${'canCreateMergeRequests'} | ${'createMergeRequestIn'}
    ${'canPushCode'}            | ${'pushCode'}
  `('$getterName', ({ getterName, permissionKey }) => {
    it.each([true, false])('finds permission for current project (%s)', val => {
      localState.projects[TEST_PROJECT_ID] = {
        userPermissions: {
          [permissionKey]: val,
        },
      };
      localState.currentProjectId = TEST_PROJECT_ID;

      expect(localStore.getters[getterName]).toBe(val);
    });
  });

  describe('entryExists', () => {
    beforeEach(() => {
      localState.entries = {
        foo: file('foo', 'foo', 'tree'),
        'foo/bar.png': file(),
      };
    });

    it.each`
      path             | deleted  | value
      ${'foo/bar.png'} | ${false} | ${true}
      ${'foo/bar.png'} | ${true}  | ${false}
      ${'foo'}         | ${false} | ${true}
    `(
      'returns $value for an existing entry path: $path (deleted: $deleted)',
      ({ path, deleted, value }) => {
        localState.entries[path].deleted = deleted;

        expect(localStore.getters.entryExists(path)).toBe(value);
      },
    );

    it('returns false for a non existing entry path', () => {
      expect(localStore.getters.entryExists('bar.baz')).toBe(false);
    });
  });

  describe('getAvailableFileName', () => {
    it.each`
      path                                          | newPath
      ${'foo'}                                      | ${'foo-1'}
      ${'foo__93.png'}                              | ${'foo__94.png'}
      ${'foo/bar.png'}                              | ${'foo/bar-1.png'}
      ${'foo/bar--34.png'}                          | ${'foo/bar--35.png'}
      ${'foo/bar 2.png'}                            | ${'foo/bar 3.png'}
      ${'foo/bar-621.png'}                          | ${'foo/bar-622.png'}
      ${'jquery.min.js'}                            | ${'jquery-1.min.js'}
      ${'my_spec_22.js.snap'}                       | ${'my_spec_23.js.snap'}
      ${'subtitles5.mp4.srt'}                       | ${'subtitles-6.mp4.srt'}
      ${'sample-file.mp3'}                          | ${'sample-file-1.mp3'}
      ${'Screenshot 2020-05-26 at 10.53.08 PM.png'} | ${'Screenshot 2020-05-26 at 11.53.08 PM.png'}
    `('suffixes the path with a number if the path already exists', ({ path, newPath }) => {
      localState.entries[path] = file();

      expect(localStore.getters.getAvailableFileName(path)).toBe(newPath);
    });

    it('loops through all incremented entries and keeps trying until a file path that does not exist is found', () => {
      localState.entries = {
        'bar/baz_1.png': file(),
        'bar/baz_2.png': file(),
        'bar/baz_3.png': file(),
        'bar/baz_4.png': file(),
        'bar/baz_5.png': file(),
        'bar/baz_72.png': file(),
      };

      expect(localStore.getters.getAvailableFileName('bar/baz_1.png')).toBe('bar/baz_6.png');
    });

    it('returns the entry path as is if the path does not exist', () => {
      expect(localStore.getters.getAvailableFileName('foo-bar1.jpg')).toBe('foo-bar1.jpg');
    });
  });

  describe('getUrlForPath', () => {
    it('returns a route url for the given path', () => {
      localState.currentProjectId = 'test/test';
      localState.currentBranchId = 'master';

      expect(localStore.getters.getUrlForPath('path/to/foo/bar-1.jpg')).toBe(
        `/project/test/test/tree/master/-/path/to/foo/bar-1.jpg/`,
      );
    });
  });

  describe('getJsonSchemaForPath', () => {
    beforeEach(() => {
      localState.currentProjectId = 'path/to/some/project';
      localState.currentBranchId = 'master';
    });

    it('returns a json schema uri and match config for a json/yaml file that can be loaded by monaco', () => {
      expect(localStore.getters.getJsonSchemaForPath('.gitlab-ci.yml')).toEqual({
        fileMatch: ['*.gitlab-ci.yml'],
        uri: `${TEST_HOST}/path/to/some/project/-/schema/master/.gitlab-ci.yml`,
      });
    });

    it('returns a path containing sha if branch details are present in state', () => {
      localState.projects['path/to/some/project'] = {
        name: 'project',
        branches: {
          master: {
            name: 'master',
            commit: {
              id: 'abcdef123456',
            },
          },
        },
      };

      expect(localStore.getters.getJsonSchemaForPath('.gitlab-ci.yml')).toEqual({
        fileMatch: ['*.gitlab-ci.yml'],
        uri: `${TEST_HOST}/path/to/some/project/-/schema/abcdef123456/.gitlab-ci.yml`,
      });
    });
  });
});
