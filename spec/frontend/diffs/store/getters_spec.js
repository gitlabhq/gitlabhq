import * as getters from '~/diffs/store/getters';
import state from '~/diffs/store/modules/diff_state';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';
import discussion from '../mock_data/diff_discussions';

describe('Diffs Module Getters', () => {
  let localState;
  let discussionMock;
  let discussionMock1;

  const diffFileMock = {
    fileHash: '9732849daca6ae818696d9575f5d1207d1a7f8bb',
  };

  beforeEach(() => {
    localState = state();
    discussionMock = { ...discussion };
    discussionMock.diff_file.file_hash = diffFileMock.fileHash;

    discussionMock1 = { ...discussion };
    discussionMock1.diff_file.file_hash = diffFileMock.fileHash;
  });

  describe('isParallelView', () => {
    it('should return true if view set to parallel view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(true);
    });

    it('should return false if view not to parallel view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isParallelView(localState)).toEqual(false);
    });
  });

  describe('isInlineView', () => {
    it('should return true if view set to inline view', () => {
      localState.diffViewType = INLINE_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(true);
    });

    it('should return false if view not to inline view', () => {
      localState.diffViewType = PARALLEL_DIFF_VIEW_TYPE;

      expect(getters.isInlineView(localState)).toEqual(false);
    });
  });

  describe('hasCollapsedFile', () => {
    it('returns true when all files are collapsed', () => {
      localState.diffFiles = [{ viewer: { collapsed: true } }, { viewer: { collapsed: true } }];

      expect(getters.hasCollapsedFile(localState)).toEqual(true);
    });

    it('returns true when at least one file is collapsed', () => {
      localState.diffFiles = [{ viewer: { collapsed: false } }, { viewer: { collapsed: true } }];

      expect(getters.hasCollapsedFile(localState)).toEqual(true);
    });
  });

  describe('commitId', () => {
    it('returns commit id when is set', () => {
      const commitID = '800f7a91';
      localState.commit = {
        id: commitID,
      };

      expect(getters.commitId(localState)).toEqual(commitID);
    });

    it('returns null when no commit is set', () => {
      expect(getters.commitId(localState)).toEqual(null);
    });
  });

  describe('diffHasAllExpandedDiscussions', () => {
    it('returns true when all discussions are expanded', () => {
      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });

    it('returns false when one discussions is collapsed', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasAllExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasAllCollapsedDiscussions', () => {
    it('returns true when all discussions are collapsed', () => {
      discussionMock.diff_file.file_hash = diffFileMock.fileHash;
      discussionMock.expanded = false;

      expect(
        getters.diffHasAllCollapsedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasAllCollapsedDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });

    it('returns false when one discussions is expanded', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasAllCollapsedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasExpandedDiscussions', () => {
    it('returns true when one of the discussions is expanded', () => {
      discussionMock1.expanded = false;

      expect(
        getters.diffHasExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when there are no discussions', () => {
      expect(
        getters.diffHasExpandedDiscussions(localState, { getDiffFileDiscussions: () => [] })(
          diffFileMock,
        ),
      ).toEqual(false);
    });

    it('returns false when no discussion is expanded', () => {
      discussionMock.expanded = false;
      discussionMock1.expanded = false;

      expect(
        getters.diffHasExpandedDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock, discussionMock1],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('diffHasDiscussions', () => {
    it('returns true when getDiffFileDiscussions returns discussions', () => {
      expect(
        getters.diffHasDiscussions(localState, {
          getDiffFileDiscussions: () => [discussionMock],
        })(diffFileMock),
      ).toEqual(true);
    });

    it('returns false when getDiffFileDiscussions returns no discussions', () => {
      expect(
        getters.diffHasDiscussions(localState, {
          getDiffFileDiscussions: () => [],
        })(diffFileMock),
      ).toEqual(false);
    });
  });

  describe('getDiffFileDiscussions', () => {
    it('returns an array with discussions when fileHash matches and the discussion belongs to a diff', () => {
      discussionMock.diff_file.file_hash = diffFileMock.file_hash;

      expect(
        getters.getDiffFileDiscussions(localState, {}, {}, { discussions: [discussionMock] })(
          diffFileMock,
        ).length,
      ).toEqual(1);
    });

    it('returns an empty array when no discussions are found in the given diff', () => {
      expect(
        getters.getDiffFileDiscussions(localState, {}, {}, { discussions: [] })(diffFileMock)
          .length,
      ).toEqual(0);
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
      localState.diffFiles = [fileA, fileB];

      expect(getters.getDiffFileByHash(localState)('456')).toEqual(fileB);
    });

    it('returns null if no matching file is found', () => {
      localState.diffFiles = [];

      expect(getters.getDiffFileByHash(localState)('123')).toBeUndefined();
    });
  });

  describe('allBlobs', () => {
    it('returns an array of blobs', () => {
      localState.treeEntries = {
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

      expect(
        getters.allBlobs(localState, {
          flatBlobsList: getters.flatBlobsList(localState),
        }),
      ).toEqual([
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
  });

  describe('currentDiffIndex', () => {
    it('returns index of currently selected diff in diffList', () => {
      localState.diffFiles = [{ file_hash: '111' }, { file_hash: '222' }, { file_hash: '333' }];
      localState.currentDiffFileId = '222';

      expect(getters.currentDiffIndex(localState)).toEqual(1);

      localState.currentDiffFileId = '333';

      expect(getters.currentDiffIndex(localState)).toEqual(2);
    });

    it('returns 0 if no diff is selected yet or diff is not found', () => {
      localState.diffFiles = [{ file_hash: '111' }, { file_hash: '222' }, { file_hash: '333' }];
      localState.currentDiffFileId = '';

      expect(getters.currentDiffIndex(localState)).toEqual(0);
    });
  });

  describe('fileLineCoverage', () => {
    beforeEach(() => {
      Object.assign(localState.coverageFiles, { files: { 'app.js': { '1': 0, '2': 5 } } });
    });

    it('returns empty object when no coverage data is available', () => {
      Object.assign(localState.coverageFiles, {});

      expect(getters.fileLineCoverage(localState)('test.js', 2)).toEqual({});
    });

    it('returns empty object when unknown filename is passed', () => {
      expect(getters.fileLineCoverage(localState)('test.js', 2)).toEqual({});
    });

    it('returns no-coverage info when correct filename and line is passed', () => {
      expect(getters.fileLineCoverage(localState)('app.js', 1)).toEqual({
        text: 'No test coverage',
        class: 'no-coverage',
      });
    });

    it('returns coverage info when correct filename and line is passed', () => {
      expect(getters.fileLineCoverage(localState)('app.js', 2)).toEqual({
        text: 'Test coverage: 5 hits',
        class: 'coverage',
      });
    });
  });
});
