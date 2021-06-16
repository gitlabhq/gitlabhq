import { clone } from 'lodash';
import {
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  TEXT_DIFF_POSITION_TYPE,
  LEGACY_DIFF_NOTE_TYPE,
  DIFF_NOTE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  MATCH_LINE_TYPE,
  INLINE_DIFF_VIEW_TYPE,
  INLINE_DIFF_LINES_KEY,
} from '~/diffs/constants';
import * as utils from '~/diffs/store/utils';
import { MERGE_REQUEST_NOTEABLE_TYPE } from '~/notes/constants';
import { noteableDataMock } from '../../notes/mock_data';
import diffFileMockData from '../mock_data/diff_file';
import { diffMetadata } from '../mock_data/diff_metadata';

const getDiffFileMock = () => JSON.parse(JSON.stringify(diffFileMockData));
const getDiffMetadataMock = () => JSON.parse(JSON.stringify(diffMetadata));

describe('DiffsStoreUtils', () => {
  describe('findDiffFile', () => {
    const files = [{ file_hash: 1, name: 'one' }];

    it('should return correct file', () => {
      expect(utils.findDiffFile(files, 1).name).toEqual('one');
      expect(utils.findDiffFile(files, 2)).toBeUndefined();
    });
  });

  describe('getReversePosition', () => {
    it('should return correct line position name', () => {
      expect(utils.getReversePosition(LINE_POSITION_RIGHT)).toEqual(LINE_POSITION_LEFT);
      expect(utils.getReversePosition(LINE_POSITION_LEFT)).toEqual(LINE_POSITION_RIGHT);
    });
  });

  describe('findIndexInInlineLines', () => {
    const expectSet = (method, lines, invalidLines) => {
      expect(method(lines, { oldLineNumber: 3, newLineNumber: 5 })).toEqual(4);
      expect(method(invalidLines || lines, { oldLineNumber: 32, newLineNumber: 53 })).toEqual(-1);
    };

    describe('findIndexInInlineLines', () => {
      it('should return correct index for given line numbers', () => {
        expectSet(utils.findIndexInInlineLines, getDiffFileMock()[INLINE_DIFF_LINES_KEY]);
      });
    });
  });

  describe('getPreviousLineIndex', () => {
    describe(`with diffViewType (inline) in split diffs`, () => {
      let diffFile;

      beforeEach(() => {
        diffFile = { ...clone(diffFileMockData) };
      });

      it('should return the correct previous line number', () => {
        expect(
          utils.getPreviousLineIndex(INLINE_DIFF_VIEW_TYPE, diffFile, {
            oldLineNumber: 3,
            newLineNumber: 5,
          }),
        ).toBe(4);
      });
    });
  });

  describe('removeMatchLine', () => {
    it('should remove match line properly by regarding the bottom parameter', () => {
      const diffFile = getDiffFileMock();
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const inlineIndex = utils.findIndexInInlineLines(
        diffFile[INLINE_DIFF_LINES_KEY],
        lineNumbers,
      );
      const atInlineIndex = diffFile[INLINE_DIFF_LINES_KEY][inlineIndex];

      utils.removeMatchLine(diffFile, lineNumbers, false);

      expect(diffFile[INLINE_DIFF_LINES_KEY][inlineIndex]).not.toEqual(atInlineIndex);

      utils.removeMatchLine(diffFile, lineNumbers, true);

      expect(diffFile[INLINE_DIFF_LINES_KEY][inlineIndex + 1]).not.toEqual(atInlineIndex);
    });
  });

  describe('addContextLines', () => {
    it(`should add context lines`, () => {
      const diffFile = getDiffFileMock();
      const inlineLines = diffFile[INLINE_DIFF_LINES_KEY];
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const contextLines = [{ lineNumber: 42, line_code: '123' }];
      const options = { inlineLines, contextLines, lineNumbers };
      const inlineIndex = utils.findIndexInInlineLines(inlineLines, lineNumbers);

      utils.addContextLines(options);

      expect(inlineLines[inlineIndex]).toEqual(contextLines[0]);
    });

    it(`should add context lines properly with bottom parameter`, () => {
      const diffFile = getDiffFileMock();
      const inlineLines = diffFile[INLINE_DIFF_LINES_KEY];
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const contextLines = [{ lineNumber: 42, line_code: '123' }];
      const options = {
        inlineLines,
        contextLines,
        lineNumbers,
        bottom: true,
      };

      utils.addContextLines(options);

      expect(inlineLines[inlineLines.length - 1]).toEqual(contextLines[0]);
    });
  });

  describe('getNoteFormData', () => {
    it('should properly create note form data', () => {
      const diffFile = getDiffFileMock();
      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        linePosition: LINE_POSITION_LEFT,
        lineRange: { start_line_code: 'abc_1_1', end_line_code: 'abc_2_2' },
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: diffFile.diff_refs.start_sha,
        head_sha: diffFile.diff_refs.head_sha,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
        line_range: options.lineRange,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: diffFile.diff_refs.head_sha,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });

    it('should create legacy note form data', () => {
      const diffFile = getDiffFileMock();
      delete diffFile.diff_refs.start_sha;
      delete diffFile.diff_refs.head_sha;

      noteableDataMock.targetType = MERGE_REQUEST_NOTEABLE_TYPE;

      const options = {
        note: 'Hello world!',
        noteableData: noteableDataMock,
        noteableType: MERGE_REQUEST_NOTEABLE_TYPE,
        diffFile,
        noteTargetLine: {
          line_code: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_1_3',
          meta_data: null,
          new_line: 3,
          old_line: 1,
        },
        linePosition: LINE_POSITION_LEFT,
      };

      const position = JSON.stringify({
        base_sha: diffFile.diff_refs.base_sha,
        start_sha: undefined,
        head_sha: undefined,
        old_path: diffFile.old_path,
        new_path: diffFile.new_path,
        position_type: TEXT_DIFF_POSITION_TYPE,
        old_line: options.noteTargetLine.old_line,
        new_line: options.noteTargetLine.new_line,
      });

      const postData = {
        view: options.diffViewType,
        line_type: options.linePosition === LINE_POSITION_RIGHT ? NEW_LINE_TYPE : OLD_LINE_TYPE,
        merge_request_diff_head_sha: undefined,
        in_reply_to_discussion_id: '',
        note_project_id: '',
        target_type: options.noteableType,
        target_id: options.noteableData.id,
        return_discussion: true,
        note: {
          noteable_type: options.noteableType,
          noteable_id: options.noteableData.id,
          commit_id: undefined,
          type: LEGACY_DIFF_NOTE_TYPE,
          line_code: options.noteTargetLine.line_code,
          note: options.note,
          position,
        },
      };

      expect(utils.getNoteFormData(options)).toEqual({
        endpoint: options.noteableData.create_note_path,
        data: postData,
      });
    });
  });

  describe('addLineReferences', () => {
    const lineNumbers = { oldLineNumber: 3, newLineNumber: 4 };

    it('should add correct line references when bottom set to true', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers, true);

      expect(linesWithReferences[0].old_line).toEqual(lineNumbers.oldLineNumber + 1);
      expect(linesWithReferences[0].new_line).toEqual(lineNumbers.newLineNumber + 1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(4);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(5);
    });

    it('should add correct line references when bottom falsy', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }, { type: null }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers);

      expect(linesWithReferences[0].old_line).toEqual(0);
      expect(linesWithReferences[0].new_line).toEqual(1);
      expect(linesWithReferences[1].meta_data.old_pos).toEqual(2);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(3);
    });

    it('should add correct line references when isExpandDown is true', () => {
      const lines = [{ type: null }, { type: MATCH_LINE_TYPE }];
      const linesWithReferences = utils.addLineReferences(lines, lineNumbers, false, true, {
        old_line: 10,
        new_line: 11,
      });

      expect(linesWithReferences[1].meta_data.old_pos).toEqual(10);
      expect(linesWithReferences[1].meta_data.new_pos).toEqual(11);
    });
  });

  describe('trimFirstCharOfLineContent', () => {
    it('trims the line when it starts with a space', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(utils.trimFirstCharOfLineContent({ rich_text: ' diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a +', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(utils.trimFirstCharOfLineContent({ rich_text: '+diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('trims the line when it starts with a -', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(utils.trimFirstCharOfLineContent({ rich_text: '-diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('does not trims the line when it starts with a letter', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(utils.trimFirstCharOfLineContent({ rich_text: 'diff' })).toEqual({
        rich_text: 'diff',
      });
    });

    it('does not modify the provided object', () => {
      const lineObj = {
        rich_text: ' diff',
      };

      // eslint-disable-next-line import/no-deprecated
      utils.trimFirstCharOfLineContent(lineObj);

      expect(lineObj).toEqual({ rich_text: ' diff' });
    });

    it('handles a undefined or null parameter', () => {
      // eslint-disable-next-line import/no-deprecated
      expect(utils.trimFirstCharOfLineContent()).toEqual({});
    });
  });

  describe('prepareLineForRenamedFile', () => {
    const diffFile = {
      file_hash: 'file-hash',
    };
    const lineIndex = 4;
    const sourceLine = {
      foo: 'test',
      rich_text: ' <p>rich</p>', // Note the leading space
    };
    const correctLine = {
      foo: 'test',
      line_code: 'file-hash_5_5',
      old_line: 5,
      new_line: 5,
      rich_text: '<p>rich</p>', // Note no leading space
      discussionsExpanded: true,
      discussions: [],
      hasForm: false,
      text: undefined,
      alreadyPrepared: true,
    };
    let preppedLine;

    beforeEach(() => {
      preppedLine = utils.prepareLineForRenamedFile({
        diffViewType: INLINE_DIFF_VIEW_TYPE,
        line: sourceLine,
        index: lineIndex,
        diffFile,
      });
    });

    it('copies over the original line object to the new prepared line', () => {
      expect(preppedLine).toEqual(
        expect.objectContaining({
          foo: correctLine.foo,
          rich_text: correctLine.rich_text,
        }),
      );
    });

    it('correctly sets the old and new lines, plus a line code', () => {
      expect(preppedLine.old_line).toEqual(correctLine.old_line);
      expect(preppedLine.new_line).toEqual(correctLine.new_line);
      expect(preppedLine.line_code).toEqual(correctLine.line_code);
    });

    it('returns a single object with the correct structure for `inline` lines', () => {
      expect(preppedLine).toEqual(correctLine);
    });

    it.each`
      brokenSymlink
      ${false}
      ${{}}
      ${'anything except `false`'}
    `(
      "properly assigns each line's `commentsDisabled` as the same value as the parent file's `brokenSymlink` value (`$brokenSymlink`)",
      ({ brokenSymlink }) => {
        preppedLine = utils.prepareLineForRenamedFile({
          diffViewType: INLINE_DIFF_VIEW_TYPE,
          line: sourceLine,
          index: lineIndex,
          diffFile: {
            ...diffFile,
            brokenSymlink,
          },
        });

        expect(preppedLine.commentsDisabled).toStrictEqual(brokenSymlink);
      },
    );
  });

  describe('prepareDiffData', () => {
    describe('for regular diff files', () => {
      let mock;
      let preparedDiff;
      let splitInlineDiff;
      let splitParallelDiff;
      let completedDiff;

      beforeEach(() => {
        mock = getDiffFileMock();

        preparedDiff = { diff_files: [mock] };
        splitInlineDiff = {
          diff_files: [{ ...mock }],
        };
        splitParallelDiff = {
          diff_files: [{ ...mock, [INLINE_DIFF_LINES_KEY]: undefined }],
        };
        completedDiff = {
          diff_files: [{ ...mock, [INLINE_DIFF_LINES_KEY]: undefined }],
        };

        preparedDiff.diff_files = utils.prepareDiffData({ diff: preparedDiff });
        splitInlineDiff.diff_files = utils.prepareDiffData({ diff: splitInlineDiff });
        splitParallelDiff.diff_files = utils.prepareDiffData({ diff: splitParallelDiff });
        completedDiff.diff_files = utils.prepareDiffData({
          diff: completedDiff,
          priorFiles: [mock],
        });
      });

      it('sets the renderIt and collapsed attribute on files', () => {
        const checkLine = preparedDiff.diff_files[0][INLINE_DIFF_LINES_KEY][0];

        expect(checkLine.discussions.length).toBe(0);
        expect(checkLine).not.toHaveAttr('text');
        const firstChar = checkLine.rich_text.charAt(0);

        expect(firstChar).not.toBe(' ');
        expect(firstChar).not.toBe('+');
        expect(firstChar).not.toBe('-');

        expect(preparedDiff.diff_files[0].renderIt).toBeTruthy();
        expect(preparedDiff.diff_files[0].collapsed).toBeFalsy();
      });

      it('guarantees an empty array for both diff styles', () => {
        expect(splitInlineDiff.diff_files[0][INLINE_DIFF_LINES_KEY].length).toBeGreaterThan(0);
        expect(splitParallelDiff.diff_files[0][INLINE_DIFF_LINES_KEY].length).toEqual(0);
      });

      it('merges existing diff files with newly loaded diff files to ensure split diffs are eventually completed', () => {
        expect(completedDiff.diff_files.length).toEqual(1);
        expect(completedDiff.diff_files[0][INLINE_DIFF_LINES_KEY].length).toBeGreaterThan(0);
      });

      it('leaves files in the existing state', () => {
        const priorFiles = [mock];
        const fakeNewFile = {
          ...mock,
          content_sha: 'ABC',
          file_hash: 'DEF',
        };
        const updatedFilesList = utils.prepareDiffData({
          diff: { diff_files: [fakeNewFile] },
          priorFiles,
        });

        expect(updatedFilesList).toEqual([mock, fakeNewFile]);
      });

      it('completes an existing split diff without overwriting existing diffs', () => {
        // The current state has a file that has only loaded inline lines
        const priorFiles = [{ ...mock }];
        // The next (batch) load loads two files: the other half of that file, and a new file
        const fakeBatch = [
          { ...mock, [INLINE_DIFF_LINES_KEY]: undefined },
          { ...mock, [INLINE_DIFF_LINES_KEY]: undefined, content_sha: 'ABC', file_hash: 'DEF' },
        ];
        const updatedFilesList = utils.prepareDiffData({
          diff: { diff_files: fakeBatch },
          priorFiles,
        });

        expect(updatedFilesList).toEqual([
          mock,
          expect.objectContaining({
            content_sha: 'ABC',
            file_hash: 'DEF',
          }),
        ]);
      });

      it('adds the `.brokenSymlink` property to each diff file', () => {
        preparedDiff.diff_files.forEach((file) => {
          expect(file).toEqual(expect.objectContaining({ brokenSymlink: false }));
        });
      });

      it("copies the diff file's `.brokenSymlink` value to each of that file's child lines", () => {
        const lines = [
          ...preparedDiff.diff_files,
          ...splitInlineDiff.diff_files,
          ...splitParallelDiff.diff_files,
          ...completedDiff.diff_files,
        ].flatMap((file) => [...file[INLINE_DIFF_LINES_KEY]]);

        lines.forEach((line) => {
          expect(line.commentsDisabled).toBe(false);
        });
      });
    });

    describe('for diff metadata', () => {
      let mock;
      let preparedDiffFiles;

      beforeEach(() => {
        mock = getDiffMetadataMock();

        preparedDiffFiles = utils.prepareDiffData({ diff: mock, meta: true });
      });

      it('sets the renderIt and collapsed attribute on files', () => {
        expect(preparedDiffFiles[0].renderIt).toBeTruthy();
        expect(preparedDiffFiles[0].collapsed).toBeFalsy();
      });

      it('guarantees an empty array of lines for both diff styles', () => {
        expect(preparedDiffFiles[0][INLINE_DIFF_LINES_KEY].length).toEqual(0);
      });

      it('leaves files in the existing state', () => {
        const fileMock = getDiffFileMock();
        const metaData = getDiffMetadataMock();
        const priorFiles = [fileMock];
        const updatedFilesList = utils.prepareDiffData({ diff: metaData, priorFiles, meta: true });

        expect(updatedFilesList.length).toEqual(2);
        expect(updatedFilesList[0]).toEqual(fileMock);
      });

      it('adds a new file to the file that already exists in state', () => {
        // This is actually buggy behavior:
        // Because the metadata doesn't include a content_sha,
        // the de-duplicator in prepareDiffData doesn't realize it
        // should combine these two.

        // This buggy behavior hasn't caused a defect YET, because
        // `diffs_metadata.json` is only called the first time the
        // diffs app starts up, which is:
        // - after a fresh page load
        // - after you switch to the changes tab *the first time*

        // This test should begin FAILING and can be reversed to check
        // for just a single file when this is implemented:
        // https://gitlab.com/groups/gitlab-org/-/epics/2852#note_304803233

        const fileMock = getDiffFileMock();
        const metaMock = getDiffMetadataMock();
        const priorFiles = [{ ...fileMock }];
        const updatedFilesList = utils.prepareDiffData({ diff: metaMock, priorFiles, meta: true });

        expect(updatedFilesList).toEqual([
          fileMock,
          {
            ...metaMock.diff_files[0],
            [INLINE_DIFF_LINES_KEY]: [],
          },
        ]);
      });

      it('adds the `.brokenSymlink` property to each meta diff file', () => {
        preparedDiffFiles.forEach((file) => {
          expect(file).toMatchObject({ brokenSymlink: false });
        });
      });
    });
  });

  describe('isDiscussionApplicableToLine', () => {
    const diffPosition = {
      baseSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
      headSha: 'b921914f9a834ac47e6fd9420f78db0f83559130',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'ed13df29948c41ba367caa757ab3ec4892509910',
    };

    const wrongDiffPosition = {
      baseSha: 'wrong',
      headSha: 'wrong',
      newLine: null,
      newPath: '500-lines-4.txt',
      oldLine: 5,
      oldPath: '500-lines-4.txt',
      startSha: 'wrong',
    };

    const discussions = {
      upToDateDiscussion1: {
        original_position: diffPosition,
        position: wrongDiffPosition,
      },
      outDatedDiscussion1: {
        original_position: wrongDiffPosition,
        position: wrongDiffPosition,
      },
    };

    // When multi line comments are fully implemented `line_code` will be
    // included in all requests. Until then we need to ensure the logic does
    // not change when it is included only in the "comparison" argument.
    const lineRange = { start_line_code: 'abc_1_1', end_line_code: 'abc_1_2' };

    it('returns true when the discussion is up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.upToDateDiscussion1,
          diffPosition: { ...diffPosition, line_range: lineRange },
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when the discussion is not up to date', () => {
      expect(
        utils.isDiscussionApplicableToLine({
          discussion: discussions.outDatedDiscussion1,
          diffPosition: { ...diffPosition, line_range: lineRange },
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is not active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: false };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: true,
        }),
      ).toBe(false);
    });

    it('returns true when line codes match and discussion does not contain position and is active', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            line_code: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: true,
        }),
      ).toBe(true);
    });

    it('returns false when not latest diff', () => {
      const discussion = { ...discussions.outDatedDiscussion1, line_code: 'ABC_1', active: true };
      delete discussion.original_position;
      delete discussion.position;

      expect(
        utils.isDiscussionApplicableToLine({
          discussion,
          diffPosition: {
            ...diffPosition,
            lineCode: 'ABC_1',
            line_range: lineRange,
          },
          latestDiff: false,
        }),
      ).toBe(false);
    });
  });

  describe('getDiffMode', () => {
    it('returns mode when matched in file', () => {
      expect(
        utils.getDiffMode({
          renamed_file: true,
        }),
      ).toBe('renamed');
    });

    it('returns mode_changed if key has no match', () => {
      expect(
        utils.getDiffMode({
          viewer: { name: 'mode_changed' },
        }),
      ).toBe('mode_changed');
    });

    it('defaults to replaced', () => {
      expect(utils.getDiffMode({})).toBe('replaced');
    });
  });

  describe('convertExpandLines', () => {
    it('converts expanded lines to normal lines', () => {
      const diffLines = [
        {
          type: 'match',
          old_line: 1,
          new_line: 1,
        },
        {
          type: '',
          old_line: 2,
          new_line: 2,
        },
      ];

      const lines = utils.convertExpandLines({
        diffLines,
        data: [{ text: 'expanded' }],
        typeKey: 'type',
        oldLineKey: 'old_line',
        newLineKey: 'new_line',
        mapLine: ({ line, oldLine, newLine }) => ({
          ...line,
          old_line: oldLine,
          new_line: newLine,
        }),
      });

      expect(lines).toEqual([
        {
          text: 'expanded',
          new_line: 1,
          old_line: 1,
          discussions: [],
          hasForm: false,
        },
        {
          type: '',
          old_line: 2,
          new_line: 2,
        },
      ]);
    });
  });

  describe('isAdded', () => {
    it.each`
      type               | expected
      ${'new'}           | ${true}
      ${'new-nonewline'} | ${true}
      ${'old'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isAdded({ type })).toBe(expected);
    });
  });

  describe('isRemoved', () => {
    it.each`
      type               | expected
      ${'old'}           | ${true}
      ${'old-nonewline'} | ${true}
      ${'new'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isRemoved({ type })).toBe(expected);
    });
  });

  describe('isUnchanged', () => {
    it.each`
      type     | expected
      ${null}  | ${true}
      ${'new'} | ${false}
      ${'old'} | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isUnchanged({ type })).toBe(expected);
    });
  });

  describe('isMeta', () => {
    it.each`
      type               | expected
      ${'match'}         | ${true}
      ${'new-nonewline'} | ${true}
      ${'old-nonewline'} | ${true}
      ${'new'}           | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isMeta({ type })).toBe(expected);
    });
  });

  describe('isConflictMarker', () => {
    it.each`
      type                       | expected
      ${'conflict_marker_our'}   | ${true}
      ${'conflict_marker_their'} | ${true}
      ${'conflict_their'}        | ${false}
      ${'conflict_our'}          | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isConflictMarker({ type })).toBe(expected);
    });
  });

  describe('isConflictOur', () => {
    it.each`
      type                       | expected
      ${'conflict_marker_our'}   | ${false}
      ${'conflict_marker_their'} | ${false}
      ${'conflict_their'}        | ${false}
      ${'conflict_our'}          | ${true}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isConflictOur({ type })).toBe(expected);
    });
  });

  describe('isConflictTheir', () => {
    it.each`
      type                       | expected
      ${'conflict_marker_our'}   | ${false}
      ${'conflict_marker_their'} | ${false}
      ${'conflict_their'}        | ${true}
      ${'conflict_our'}          | ${false}
    `('returns $expected when type is $type', ({ type, expected }) => {
      expect(utils.isConflictTheir({ type })).toBe(expected);
    });
  });

  describe('parallelizeDiffLines', () => {
    it('converts inline diff lines to parallel diff lines', () => {
      const file = getDiffFileMock();

      expect(utils.parallelizeDiffLines(file[INLINE_DIFF_LINES_KEY])).toMatchObject(
        file.parallel_diff_lines,
      );
    });

    it('converts conflicted diffs line', () => {
      const lines = [
        { type: 'new' },
        { type: 'conflict_marker_our' },
        { type: 'conflict_our' },
        { type: 'conflict_marker' },
        { type: 'conflict_their' },
        { type: 'conflict_marker_their' },
      ];

      expect(utils.parallelizeDiffLines(lines)).toEqual([
        {
          left: null,
          right: {
            chunk: 0,
            type: 'new',
          },
        },
        {
          left: { chunk: 0, type: 'conflict_marker_our' },
          right: { chunk: 0, type: 'conflict_marker_their' },
        },
        {
          left: { chunk: 0, type: 'conflict_our' },
          right: { chunk: 0, type: 'conflict_their' },
        },
      ]);
    });

    it('converts inline diff lines', () => {
      const file = getDiffFileMock();
      const files = utils.parallelizeDiffLines(file.highlighted_diff_lines, true);

      expect(files[5].left).toMatchObject(file.parallel_diff_lines[5].left);
      expect(files[5].right).toBeNull();
      expect(files[6].left).toMatchObject(file.parallel_diff_lines[5].right);
      expect(files[6].right).toBeNull();
    });
  });
});
