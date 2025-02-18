import { createTestingPinia } from '@pinia/testing';
import {
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  INLINE_DIFF_LINES_KEY,
  DIFF_COMPARE_BASE_VERSION_INDEX,
  DIFF_COMPARE_HEAD_VERSION_INDEX,
} from '~/diffs/constants';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import setWindowLocation from 'helpers/set_window_location_helper';
import { createCustomGetters } from 'helpers/pinia_helpers';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useNotes } from '~/notes/store/legacy_notes';
import { globalAccessorPlugin } from '~/pinia/plugins';
import discussion from '../../mock_data/diff_discussions';
import diffsMockData from '../../mock_data/merge_request_diffs';

describe('Diffs Module Getters', () => {
  let getters;
  let notesGetters;

  createTestingPinia({
    plugins: [
      createCustomGetters(() => ({
        legacyDiffs: getters,
        legacyNotes: notesGetters,
        legacyMrNotes: {},
        batchComments: {},
      })),
      globalAccessorPlugin,
    ],
  });

  let store;
  let discussionMock;
  let discussionMock1;

  const diffFileMock = {
    fileHash: '9732849daca6ae818696d9575f5d1207d1a7f8bb',
  };

  beforeEach(() => {
    getters = {};
    notesGetters = {};
    store = useLegacyDiffs();
    useMrNotes();
    useNotes().$reset();
    store.$reset();
    discussionMock = { ...discussion };
    discussionMock.diff_file.file_hash = diffFileMock.fileHash;

    discussionMock1 = { ...discussion };
    discussionMock1.diff_file.file_hash = diffFileMock.fileHash;
  });

  describe('isParallelView', () => {
    it('should return true if view set to parallel view', () => {
      store.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(store.isParallelView).toEqual(true);
    });

    it('should return false if view not to parallel view', () => {
      store.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(store.isParallelView).toEqual(false);
    });
  });

  describe('isInlineView', () => {
    it('should return true if view set to inline view', () => {
      store.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(store.isInlineView).toEqual(true);
    });

    it('should return false if view not to inline view', () => {
      store.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(store.isInlineView).toEqual(false);
    });
  });

  describe('whichCollapsedTypes', () => {
    const autoCollapsedFile = { viewer: { automaticallyCollapsed: true, manuallyCollapsed: null } };
    const manuallyCollapsedFile = {
      viewer: { automaticallyCollapsed: false, manuallyCollapsed: true },
    };
    const openFile = { viewer: { automaticallyCollapsed: false, manuallyCollapsed: false } };

    it.each`
      description                                 | value    | files
      ${'all files are automatically collapsed'}  | ${true}  | ${[{ ...autoCollapsedFile }, { ...autoCollapsedFile }]}
      ${'all files are manually collapsed'}       | ${true}  | ${[{ ...manuallyCollapsedFile }, { ...manuallyCollapsedFile }]}
      ${'no files are collapsed in any way'}      | ${false} | ${[{ ...openFile }, { ...openFile }]}
      ${'some files are collapsed in either way'} | ${true}  | ${[{ ...manuallyCollapsedFile }, { ...autoCollapsedFile }, { ...openFile }]}
    `('`any` is $value when $description', ({ value, files }) => {
      store.diffFiles = files;

      const getterResult = store.whichCollapsedTypes;

      expect(getterResult.any).toEqual(value);
    });

    it.each`
      description                                 | value    | files
      ${'all files are automatically collapsed'}  | ${true}  | ${[{ ...autoCollapsedFile }, { ...autoCollapsedFile }]}
      ${'all files are manually collapsed'}       | ${false} | ${[{ ...manuallyCollapsedFile }, { ...manuallyCollapsedFile }]}
      ${'no files are collapsed in any way'}      | ${false} | ${[{ ...openFile }, { ...openFile }]}
      ${'some files are collapsed in either way'} | ${true}  | ${[{ ...manuallyCollapsedFile }, { ...autoCollapsedFile }, { ...openFile }]}
    `('`automatic` is $value when $description', ({ value, files }) => {
      store.diffFiles = files;

      const getterResult = store.whichCollapsedTypes;

      expect(getterResult.automatic).toEqual(value);
    });

    it.each`
      description                                 | value    | files
      ${'all files are automatically collapsed'}  | ${false} | ${[{ ...autoCollapsedFile }, { ...autoCollapsedFile }]}
      ${'all files are manually collapsed'}       | ${true}  | ${[{ ...manuallyCollapsedFile }, { ...manuallyCollapsedFile }]}
      ${'no files are collapsed in any way'}      | ${false} | ${[{ ...openFile }, { ...openFile }]}
      ${'some files are collapsed in either way'} | ${true}  | ${[{ ...manuallyCollapsedFile }, { ...autoCollapsedFile }, { ...openFile }]}
    `('`manual` is $value when $description', ({ value, files }) => {
      store.diffFiles = files;

      const getterResult = store.whichCollapsedTypes;

      expect(getterResult.manual).toEqual(value);
    });
  });

  describe('commitId', () => {
    it('returns commit id when is set', () => {
      const commitID = '800f7a91';
      store.commit = {
        id: commitID,
      };

      expect(store.commitId).toEqual(commitID);
    });

    it('returns null when no commit is set', () => {
      expect(store.commitId).toEqual(null);
    });
  });

  describe('diffHasAllExpandedDiscussions', () => {
    it('returns true when all discussions are expanded', () => {
      getters = {
        getDiffFileDiscussions: () => [discussionMock, discussionMock],
      };
      expect(store.diffHasAllExpandedDiscussions(diffFileMock)).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      getters = {
        getDiffFileDiscussions: () => [],
      };
      expect(store.diffHasAllExpandedDiscussions(diffFileMock)).toEqual(false);
    });

    it('returns false when one discussions is collapsed', () => {
      discussionMock1.expanded = false;
      getters = {
        getDiffFileDiscussions: () => [discussionMock, discussionMock1],
      };

      expect(store.diffHasAllExpandedDiscussions(diffFileMock)).toEqual(false);
    });
  });

  describe('diffHasAllCollapsedDiscussions', () => {
    it('returns true when all discussions are collapsed', () => {
      discussionMock.diff_file.file_hash = diffFileMock.fileHash;
      discussionMock.expanded = false;
      getters = {
        getDiffFileDiscussions: () => [discussionMock],
      };

      expect(store.diffHasAllCollapsedDiscussions(diffFileMock)).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      getters = {
        getDiffFileDiscussions: () => [],
      };
      expect(store.diffHasAllCollapsedDiscussions(diffFileMock)).toEqual(false);
    });

    it('returns false when one discussions is expanded', () => {
      discussionMock1.expanded = false;
      getters = {
        getDiffFileDiscussions: () => [discussionMock, discussionMock1],
      };

      expect(store.diffHasAllCollapsedDiscussions(diffFileMock)).toEqual(false);
    });
  });

  describe('diffHasExpandedDiscussions', () => {
    it('returns true when one of the discussions is expanded', () => {
      const diffFile = {
        parallel_diff_lines: [],
        highlighted_diff_lines: [
          {
            discussions: [discussionMock, discussionMock],
            discussionsExpanded: true,
          },
        ],
      };

      expect(store.diffHasExpandedDiscussions(diffFile)).toEqual(true);
    });

    it('returns true when file discussion is expanded', () => {
      const diffFile = {
        discussions: [{ ...discussionMock, expandedOnDiff: true }],
        highlighted_diff_lines: [],
      };

      expect(store.diffHasExpandedDiscussions(diffFile)).toEqual(true);
    });

    it('returns false when file discussion is expanded', () => {
      const diffFile = {
        discussions: [{ ...discussionMock, expanded: false }],
        highlighted_diff_lines: [],
      };

      expect(store.diffHasExpandedDiscussions(diffFile)).toEqual(false);
    });

    it('returns false when there are no discussions', () => {
      const diffFile = {
        parallel_diff_lines: [],
        highlighted_diff_lines: [
          {
            discussions: [],
            discussionsExpanded: true,
          },
        ],
      };
      expect(store.diffHasExpandedDiscussions(diffFile)).toEqual(false);
    });

    it('returns false when no discussion is expanded', () => {
      const diffFile = {
        parallel_diff_lines: [],
        highlighted_diff_lines: [
          {
            discussions: [discussionMock, discussionMock],
            discussionsExpanded: false,
          },
        ],
      };

      expect(store.diffHasExpandedDiscussions(diffFile)).toEqual(false);
    });
  });

  describe('diffHasDiscussions', () => {
    it('returns true when getDiffFileDiscussions returns discussions', () => {
      const diffFile = {
        parallel_diff_lines: [],
        highlighted_diff_lines: [
          {
            discussions: [discussionMock, discussionMock],
            discussionsExpanded: false,
          },
        ],
      };

      expect(store.diffHasDiscussions(diffFile)).toEqual(true);
    });

    it('returns true when file has discussions', () => {
      const diffFile = {
        discussions: [discussionMock, discussionMock],
        highlighted_diff_lines: [],
      };

      expect(store.diffHasDiscussions(diffFile)).toEqual(true);
    });

    it('returns false when getDiffFileDiscussions returns no discussions', () => {
      const diffFile = {
        parallel_diff_lines: [],
        highlighted_diff_lines: [
          {
            discussions: [],
            discussionsExpanded: false,
          },
        ],
      };

      expect(store.diffHasDiscussions(diffFile)).toEqual(false);
    });
  });

  describe('getDiffFileDiscussions', () => {
    it('returns an array with discussions when fileHash matches and the discussion belongs to a diff', () => {
      discussionMock.diff_file.file_hash = diffFileMock.file_hash;
      useNotes().discussions = [discussionMock];

      expect(store.getDiffFileDiscussions(diffFileMock).length).toEqual(1);
    });

    it('returns an empty array when no discussions are found in the given diff', () => {
      useNotes().discussions = [];
      expect(store.getDiffFileDiscussions(diffFileMock).length).toEqual(0);
    });
  });

  describe('getDiffFileByHash', () => {
    it('returns file by hash', () => {
      const fileA = {
        file_hash: '123',
      };
      const fileB = {
        file_hash: '456',
      };
      store.diffFiles = [fileA, fileB];

      expect(store.getDiffFileByHash('456')).toEqual(fileB);
    });

    it('returns null if no matching file is found', () => {
      store.diffFiles = [];

      expect(store.getDiffFileByHash('123')).toBeUndefined();
    });
  });

  describe('isTreePathLoaded', () => {
    it.each`
      desc                                         | loaded   | path             | bool
      ${'the file exists and has been loaded'}     | ${true}  | ${'path/tofile'} | ${true}
      ${'the file exists and has not been loaded'} | ${false} | ${'path/tofile'} | ${false}
      ${'the file does not exist'}                 | ${false} | ${'tofile/path'} | ${false}
    `('returns $bool when $desc', ({ loaded, path, bool }) => {
      store.treeEntries['path/tofile'] = { diffLoaded: loaded };

      expect(store.isTreePathLoaded(path)).toBe(bool);
    });
  });

  describe('allBlobs', () => {
    it('returns an array of blobs', () => {
      store.treeEntries = {
        file: {
          type: 'blob',
          path: 'file',
          parentPath: '/',
          tree: [],
        },
        tree: {
          type: 'tree',
          path: 'tree',
          parentPath: '/',
          tree: [],
        },
      };

      expect(store.allBlobs).toEqual([
        {
          isHeader: true,
          path: '/',
          tree: [
            {
              parentPath: '/',
              path: 'file',
              tree: [],
              type: 'blob',
            },
          ],
        },
      ]);
    });

    it('assigns ids to files', () => {
      store.treeEntries = {
        file: {
          type: 'blob',
          path: 'file',
          parentPath: '/',
          fileHash: '111',
          tree: [],
        },
      };
      store.diffFiles = [{ id: '222', file_hash: '111' }];

      expect(store.allBlobs).toEqual([
        {
          isHeader: true,
          path: '/',
          tree: [
            {
              parentPath: '/',
              path: 'file',
              tree: [],
              type: 'blob',
              fileHash: '111',
              id: '222',
            },
          ],
        },
      ]);
    });
  });

  describe('currentDiffIndex', () => {
    it('returns index of currently selected diff in diffList', () => {
      store.treeEntries = [
        { type: 'blob', fileHash: '111' },
        { type: 'blob', fileHash: '222' },
        { type: 'blob', fileHash: '333' },
      ];
      store.currentDiffFileId = '222';

      expect(store.currentDiffIndex).toEqual(1);

      store.currentDiffFileId = '333';

      expect(store.currentDiffIndex).toEqual(2);
    });

    it('returns 0 if no diff is selected yet or diff is not found', () => {
      store.treeEntries = [
        { type: 'blob', fileHash: '111' },
        { type: 'blob', fileHash: '222' },
        { type: 'blob', fileHash: '333' },
      ];
      store.currentDiffFileId = '';

      expect(store.currentDiffIndex).toEqual(0);
    });
  });

  describe('fileLineCoverage', () => {
    beforeEach(() => {
      Object.assign(store.coverageFiles, { files: { 'app.js': { 1: 0, 2: 5 } } });
    });

    it('returns empty object when no coverage data is available', () => {
      Object.assign(store.coverageFiles, {});

      expect(store.fileLineCoverage('test.js', 2)).toEqual({});
    });

    it('returns empty object when unknown filename is passed', () => {
      expect(store.fileLineCoverage('test.js', 2)).toEqual({});
    });

    it('returns no-coverage info when correct filename and line is passed', () => {
      expect(store.fileLineCoverage('app.js', 1)).toEqual({
        text: 'No test coverage',
        class: 'no-coverage',
      });
    });

    it('returns coverage info when correct filename and line is passed', () => {
      expect(store.fileLineCoverage('app.js', 2)).toEqual({
        text: 'Test coverage: 5 hits',
        class: 'coverage',
      });
    });
  });

  describe('suggestionCommitMessage', () => {
    beforeEach(() => {
      store.defaultSuggestionCommitMessage =
        '%{branch_name}%{project_path}%{project_name}%{username}%{user_full_name}%{file_paths}%{suggestions_count}%{files_count}';
      useMrNotes().$patch({
        mrMetadata: {
          branch_name: 'branch',
          project_path: '/path',
          project_name: 'name',
          username: 'user',
          user_full_name: 'user userton',
        },
      });
    });

    it.each`
      specialState                | output
      ${{}}                       | ${'branch/pathnameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ user_full_name: null }} | ${'branch/pathnameuser%{user_full_name}%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ username: null }}       | ${'branch/pathname%{username}user userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ project_name: null }}   | ${'branch/path%{project_name}useruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ project_path: null }}   | ${'branch%{project_path}nameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ branch_name: null }}    | ${'%{branch_name}/pathnameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
    `(
      'provides the correct "base" default commit message based on state ($specialState)',
      ({ specialState, output }) => {
        useMrNotes().$patch({ mrMetadata: specialState });

        expect(store.suggestionCommitMessage()).toBe(output);
      },
    );

    it.each`
      stateOverrides              | output
      ${{}}                       | ${'branch/pathnameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ user_full_name: null }} | ${'branch/pathnameuser%{user_full_name}%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ username: null }}       | ${'branch/pathname%{username}user userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ project_name: null }}   | ${'branch/path%{project_name}useruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ project_path: null }}   | ${'branch%{project_path}nameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
      ${{ branch_name: null }}    | ${'%{branch_name}/pathnameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
    `(
      "properly overrides state values ($stateOverrides) if they're provided",
      ({ stateOverrides, output }) => {
        expect(store.suggestionCommitMessage(stateOverrides)).toBe(output);
      },
    );

    it.each`
      providedValues                                                          | output
      ${{ file_paths: 'path1, path2', suggestions_count: 1, files_count: 1 }} | ${'branch/pathnameuseruser usertonpath1, path211'}
      ${{ suggestions_count: 1, files_count: 1 }}                             | ${'branch/pathnameuseruser userton%{file_paths}11'}
      ${{ file_paths: 'path1, path2', files_count: 1 }}                       | ${'branch/pathnameuseruser usertonpath1, path2%{suggestions_count}1'}
      ${{ file_paths: 'path1, path2', suggestions_count: 1 }}                 | ${'branch/pathnameuseruser usertonpath1, path21%{files_count}'}
      ${{ something_unused: 'CrAzY TeXt' }}                                   | ${'branch/pathnameuseruser userton%{file_paths}%{suggestions_count}%{files_count}'}
    `(
      "fills in any missing interpolations ($providedValues) when they're provided at the getter callsite",
      ({ providedValues, output }) => {
        expect(store.suggestionCommitMessage(providedValues)).toBe(output);
      },
    );
  });

  describe('diffFilesFiltered', () => {
    it('proxies diffFiles state', () => {
      const diffFiles = [getDiffFileMock()];
      store.diffFiles = diffFiles;
      expect(store.diffFilesFiltered).toStrictEqual(diffFiles);
    });

    it('links the file', () => {
      const linkedFile = getDiffFileMock();
      const regularFile = getDiffFileMock();
      store.diffFiles = [regularFile, linkedFile];
      expect(store.diffFilesFiltered).toStrictEqual([linkedFile, regularFile]);
    });
  });

  describe('linkedFile', () => {
    it('returns linkedFile', () => {
      const linkedFile = getDiffFileMock();
      store.diffFiles = [linkedFile];
      store.linkedFileHash = linkedFile.file_hash;
      expect(store.linkedFile).toStrictEqual(linkedFile);
    });

    it('returns null if no linked file is set', () => {
      expect(store.linkedFile).toBe(null);
    });
  });

  describe('fileTree', () => {
    it('returns fileTree', () => {
      const diffFiles = [
        { id: '111', file_hash: '222' },
        { id: '333', file_hash: '444' },
      ];
      const tree = {
        type: 'tree',
        path: 'tree',
        parentPath: '/',
        fileHash: '444',
        tree: [{ fileHash: '222', tree: [] }],
      };
      store.diffFiles = diffFiles;
      store.tree = [tree];
      expect(store.fileTree).toStrictEqual([
        { ...tree, id: '333', tree: [{ ...tree.tree[0], id: '111' }] },
      ]);
    });
  });

  describe('allDiffDiscussionsExpanded', () => {
    it('returns true when all line discussions are expanded', () => {
      store.diffFiles = [
        {
          [INLINE_DIFF_LINES_KEY]: [
            { discussionsExpanded: true, discussions: [{}] },
            { discussionsExpanded: true, discussions: [{}] },
          ],
        },
      ];
      expect(store.allDiffDiscussionsExpanded).toBe(true);
    });

    it('returns false if at least one line discussion is collapsed', () => {
      store.diffFiles = [
        {
          [INLINE_DIFF_LINES_KEY]: [
            { discussionsExpanded: true, discussions: [{}] },
            { discussionsExpanded: false, discussions: [{}] },
          ],
        },
      ];
      expect(store.allDiffDiscussionsExpanded).toBe(false);
    });

    it('returns false if at least one image discussion is collapsed', () => {
      store.diffFiles = [
        {
          [INLINE_DIFF_LINES_KEY]: [
            { discussionsExpanded: true, discussions: [{}] },
            { discussionsExpanded: true, discussions: [{}] },
          ],
        },
        {
          [INLINE_DIFF_LINES_KEY]: [],
          viewer: { name: 'image' },
          discussions: [{ expandedOnDiff: false }],
        },
      ];
      expect(store.allDiffDiscussionsExpanded).toBe(false);
    });

    it('returns true if all image discussions are expanded', () => {
      store.diffFiles = [
        {
          viewer: { name: 'text' },
          [INLINE_DIFF_LINES_KEY]: [],
          discussions: [],
        },
        {
          viewer: { name: 'image' },
          [INLINE_DIFF_LINES_KEY]: [],
          discussions: [{ expandedOnDiff: true }, { expandedOnDiff: true }],
        },
      ];
      expect(store.allDiffDiscussionsExpanded).toBe(true);
    });
  });

  describe('Compare diff version dropdowns', () => {
    beforeEach(() => {
      store.mergeRequestDiff = {
        base_version_path: 'basePath',
        head_version_path: 'headPath',
        version_index: 1,
      };
      store.targetBranchName = 'baseVersion';
      store.mergeRequestDiffs = diffsMockData;
    });

    describe('selectedTargetIndex', () => {
      it('without startVersion', () => {
        expect(store.selectedTargetIndex).toEqual(DIFF_COMPARE_BASE_VERSION_INDEX);
      });

      it('with startVersion', () => {
        const startVersion = { version_index: 1 };
        store.startVersion = startVersion;
        expect(store.selectedTargetIndex).toEqual(startVersion.version_index);
      });
    });

    it('selectedSourceIndex', () => {
      expect(store.selectedSourceIndex).toEqual(store.mergeRequestDiff.version_index);
    });

    describe('diffCompareDropdownTargetVersions', () => {
      // diffCompareDropdownTargetVersions slices the array at the first position
      // and appends a "base" and "head" version at the end of the list so that
      // "base" and "head" appear at the bottom of the dropdown
      // this is also why we use diffsMockData[1] for the "first" version

      let expectedFirstVersion;
      let expectedBaseVersion;
      let expectedHeadVersion;
      const originalLocation = window.location.href;

      const setupTest = (includeDiffHeadParam) => {
        const diffHeadParam = includeDiffHeadParam ? '?diff_head=true' : '';

        setWindowLocation(diffHeadParam);

        expectedFirstVersion = {
          ...diffsMockData[1],
          href: expect.any(String),
          versionName: expect.any(String),
          selected: false,
        };

        expectedBaseVersion = {
          versionName: 'baseVersion',
          version_index: DIFF_COMPARE_BASE_VERSION_INDEX,
          href: 'basePath',
          isBase: true,
          selected: false,
        };

        expectedHeadVersion = {
          versionName: 'baseVersion',
          version_index: DIFF_COMPARE_HEAD_VERSION_INDEX,
          href: 'headPath',
          isHead: true,
          selected: false,
        };
      };

      const assertVersions = (targetVersions, checkBaseVersion) => {
        const targetLatestVersion = targetVersions[targetVersions.length - 1];
        expect(targetVersions[0]).toEqual(expectedFirstVersion);

        if (checkBaseVersion) {
          expect(targetLatestVersion).toEqual(expectedBaseVersion);
        } else {
          expect(targetLatestVersion).toEqual(expectedHeadVersion);
        }
      };

      afterEach(() => {
        setWindowLocation(originalLocation);
      });

      it('head version selected', () => {
        setupTest(true);

        expectedHeadVersion.selected = true;

        const targetVersions = store.diffCompareDropdownTargetVersions;
        assertVersions(targetVersions);
      });

      it('first version selected', () => {
        // NOTE: It should not be possible to have both "diff_head=true" and
        // have anything other than the head version selected, but the user could
        // manually add "?diff_head=true" to the url. In this instance we still
        // want the actual selected version to display as "selected"
        // Passing in "true" here asserts that first version is still selected
        // even if "diff_head" is present in the url
        setupTest(true);

        expectedFirstVersion.selected = true;
        store.startVersion = expectedFirstVersion;

        getters.selectedTargetIndex = expectedFirstVersion.version_index;

        const targetVersions = store.diffCompareDropdownTargetVersions;
        assertVersions(targetVersions);
      });

      describe('when state.mergeRequestDiff.head_version_path is null', () => {
        beforeEach(() => {
          store.mergeRequestDiff.head_version_path = null;
        });

        it('base version selected', () => {
          setupTest(true);

          expectedBaseVersion.selected = true;

          const targetVersions = store.diffCompareDropdownTargetVersions;
          assertVersions(targetVersions, true);
        });
      });
    });

    it('diffCompareDropdownSourceVersions', () => {
      const firstDiff = store.mergeRequestDiffs[0];
      const expectedShape = {
        ...firstDiff,
        href: firstDiff.version_path,
        commitsText: `${firstDiff.commits_count} commits,`,
        isLatestVersion: true,
        versionName: 'latest version',
        selected: true,
      };

      getters.selectedSourceIndex = expectedShape.version_index;

      const sourceVersions = store.diffCompareDropdownSourceVersions;
      expect(sourceVersions[0]).toEqual(expectedShape);
      expect(sourceVersions[1]).toMatchObject({
        selected: false,
        isLatestVersion: false,
      });
    });
  });
});
