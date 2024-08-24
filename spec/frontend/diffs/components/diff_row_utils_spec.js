import * as utils from '~/diffs/components/diff_row_utils';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
} from '~/diffs/constants';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import setWindowLocation from 'helpers/set_window_location_helper';

const LINE_CODE = 'abc123';

function problemsClone({
  brokenSymlink = false,
  brokenLineCode = false,
  fileOnlyMoved = false,
} = {}) {
  return {
    brokenSymlink,
    brokenLineCode,
    fileOnlyMoved,
  };
}

describe('diff_row_utils', () => {
  describe('isHighlighted', () => {
    it('should return true if line is highlighted', () => {
      const line = { line_code: LINE_CODE };
      const isCommented = false;
      expect(utils.isHighlighted(LINE_CODE, line, isCommented)).toBe(true);
    });

    it('should return false if line is not highlighted', () => {
      const line = { line_code: LINE_CODE };
      const isCommented = false;
      expect(utils.isHighlighted('xxx', line, isCommented)).toBe(false);
    });

    it('should return true if isCommented is true', () => {
      const line = { line_code: LINE_CODE };
      const isCommented = true;
      expect(utils.isHighlighted('xxx', line, isCommented)).toBe(true);
    });
  });

  describe('isContextLine', () => {
    it('return true if line type is context', () => {
      expect(utils.isContextLine(CONTEXT_LINE_TYPE)).toBe(true);
    });

    it('return false if line type is not context', () => {
      expect(utils.isContextLine('xxx')).toBe(false);
    });
  });

  describe('isMatchLine', () => {
    it('return true if line type is match', () => {
      expect(utils.isMatchLine(MATCH_LINE_TYPE)).toBe(true);
    });

    it('return false if line type is not match', () => {
      expect(utils.isMatchLine('xxx')).toBe(false);
    });
  });

  describe('isMetaLine', () => {
    it.each`
      type                    | expectation
      ${OLD_NO_NEW_LINE_TYPE} | ${true}
      ${NEW_NO_NEW_LINE_TYPE} | ${true}
      ${EMPTY_CELL_TYPE}      | ${true}
      ${'xxx'}                | ${false}
    `('should return $expectation if type is $type', ({ type, expectation }) => {
      expect(utils.isMetaLine(type)).toBe(expectation);
    });
  });

  describe('shouldRenderCommentButton', () => {
    it('should return false if comment button is not rendered', () => {
      expect(utils.shouldRenderCommentButton(true, false)).toBe(false);
    });

    it('should return false if not logged in', () => {
      expect(utils.shouldRenderCommentButton(false, true)).toBe(false);
    });

    it('should return true logged in and rendered', () => {
      expect(utils.shouldRenderCommentButton(true, true)).toBe(true);
    });
  });

  describe('hasDiscussions', () => {
    it('should return false if line is undefined', () => {
      expect(utils.hasDiscussions()).toBe(false);
    });

    it('should return false if discussions is undefined', () => {
      expect(utils.hasDiscussions({})).toBe(false);
    });

    it('should return false if discussions has legnth of 0', () => {
      expect(utils.hasDiscussions({ discussions: [] })).toBe(false);
    });

    it('should return true if discussions has legnth > 0', () => {
      expect(utils.hasDiscussions({ discussions: [1] })).toBe(true);
    });
  });

  describe('lineHref', () => {
    it(`should return #${LINE_CODE}`, () => {
      expect(utils.lineHref({ line_code: LINE_CODE }, {})).toContain(`#${LINE_CODE}`);
    });

    it(`should return empty string if line is undefined`, () => {
      expect(utils.lineHref()).toEqual('');
    });

    it(`should return empty string if line_code is undefined`, () => {
      expect(utils.lineHref({}, {})).toEqual('');
    });

    it(`should retain diff_id`, () => {
      const newLocation = new URL(window.location);
      newLocation.searchParams.append('diff_id', 'foo');
      setWindowLocation(newLocation.toString());
      expect(utils.lineHref({ line_code: LINE_CODE }, {})).toContain(`?diff_id=foo`);
    });

    describe('linked file enabled', () => {
      it(`should return linked file URL`, () => {
        const diffFile = getDiffFileMock();
        expect(utils.lineHref({ line_code: LINE_CODE }, diffFile)).toContain(
          `?file=${diffFile.file_hash}#${LINE_CODE}`,
        );
      });
    });
  });

  describe('createFileUrl', () => {
    it(`should return linked file URL`, () => {
      const diffFile = getDiffFileMock();
      const url = utils.createFileUrl(diffFile);
      expect(url.searchParams.get('file')).toBe(diffFile.file_hash);
      expect(url.hash).toBe(`#diff-content-${diffFile.file_hash}`);
    });

    it(`removes existing linked file search param`, () => {
      const newLocation = new URL(window.location);
      newLocation.searchParams.append('file', 'foo');
      setWindowLocation(newLocation.toString());
      const diffFile = getDiffFileMock();
      const url = utils.createFileUrl(diffFile);
      expect(url.searchParams.get('file')).toBe(diffFile.file_hash);
      expect(url.hash).toBe(`#diff-content-${diffFile.file_hash}`);
    });
  });

  describe('lineCode', () => {
    it(`should return undefined if line_code is undefined`, () => {
      expect(utils.lineCode()).toEqual(undefined);
      expect(utils.lineCode({ left: {} })).toEqual(undefined);
      expect(utils.lineCode({ right: {} })).toEqual(undefined);
    });

    it(`should return ${LINE_CODE}`, () => {
      expect(utils.lineCode({ line_code: LINE_CODE })).toEqual(LINE_CODE);
      expect(utils.lineCode({ left: { line_code: LINE_CODE } })).toEqual(LINE_CODE);
      expect(utils.lineCode({ right: { line_code: LINE_CODE } })).toEqual(LINE_CODE);
    });
  });

  describe('classNameMapCell', () => {
    it.each`
      line               | highlighted | commented | selectionStart | selectionEnd | isLoggedIn | isHover  | expectation
      ${undefined}       | ${true}     | ${false}  | ${false}       | ${false}     | ${true}    | ${true}  | ${[{ 'highlight-top': true, 'highlight-bottom': true, hll: true, commented: false }]}
      ${undefined}       | ${false}    | ${true}   | ${false}       | ${false}     | ${true}    | ${true}  | ${[{ 'highlight-top': false, 'highlight-bottom': false, hll: false, commented: true }]}
      ${{ type: 'new' }} | ${false}    | ${false}  | ${false}       | ${false}     | ${false}   | ${false} | ${[{ new: true, 'highlight-top': false, 'highlight-bottom': false, hll: false, commented: false, 'is-over': false, new_line: true, old_line: false }]}
      ${{ type: 'new' }} | ${true}     | ${false}  | ${false}       | ${false}     | ${true}    | ${false} | ${[{ new: true, 'highlight-top': true, 'highlight-bottom': true, hll: true, commented: false, 'is-over': false, new_line: true, old_line: false }]}
      ${{ type: 'new' }} | ${true}     | ${false}  | ${false}       | ${false}     | ${false}   | ${true}  | ${[{ new: true, 'highlight-top': true, 'highlight-bottom': true, hll: true, commented: false, 'is-over': false, new_line: true, old_line: false }]}
      ${{ type: 'new' }} | ${true}     | ${false}  | ${false}       | ${false}     | ${true}    | ${true}  | ${[{ new: true, 'highlight-top': true, 'highlight-bottom': true, hll: true, commented: false, 'is-over': true, new_line: true, old_line: false }]}
    `(
      'should return $expectation',
      ({
        line,
        highlighted,
        commented,
        selectionStart,
        selectionEnd,
        isLoggedIn,
        isHover,
        expectation,
      }) => {
        const classes = utils.classNameMapCell({
          line,
          highlighted,
          commented,
          selectionStart,
          selectionEnd,
          isLoggedIn,
          isHover,
        });
        expect(classes).toEqual(expectation);
      },
    );
  });

  describe('addCommentTooltip', () => {
    const brokenSymLinkTooltip =
      'Commenting on symbolic links that replace or are replaced by files is not supported';
    const brokenRealTooltip =
      'Commenting on files that replace or are replaced by symbolic links is not supported';
    const lineMovedOrRenamedFileTooltip =
      'Commenting on files that are only moved or renamed is not supported';
    const lineWithNoLineCodeTooltip = 'Commenting on this line is not supported';
    const dragTooltip = 'Add a comment to this line or drag for multiple lines';

    it('should return default tooltip', () => {
      expect(utils.addCommentTooltip()).toBeUndefined();
    });

    it('should return drag comment tooltip when dragging is enabled', () => {
      expect(utils.addCommentTooltip({ problems: problemsClone() })).toEqual(dragTooltip);
    });

    it('should return broken symlink tooltip', () => {
      expect(
        utils.addCommentTooltip({
          problems: problemsClone({ brokenSymlink: { wasSymbolic: true } }),
        }),
      ).toEqual(brokenSymLinkTooltip);
      expect(
        utils.addCommentTooltip({
          problems: problemsClone({ brokenSymlink: { isSymbolic: true } }),
        }),
      ).toEqual(brokenSymLinkTooltip);
    });

    it('should return broken real tooltip', () => {
      expect(
        utils.addCommentTooltip({ problems: problemsClone({ brokenSymlink: { wasReal: true } }) }),
      ).toEqual(brokenRealTooltip);
      expect(
        utils.addCommentTooltip({ problems: problemsClone({ brokenSymlink: { isReal: true } }) }),
      ).toEqual(brokenRealTooltip);
    });

    it('reports a tooltip when the line is in a file that has only been moved or renamed', () => {
      expect(utils.addCommentTooltip({ problems: problemsClone({ fileOnlyMoved: true }) })).toEqual(
        lineMovedOrRenamedFileTooltip,
      );
    });

    it("reports a tooltip when the line doesn't have a line code to leave a comment on", () => {
      expect(
        utils.addCommentTooltip({ problems: problemsClone({ brokenLineCode: true }) }),
      ).toEqual(lineWithNoLineCodeTooltip);
    });
  });

  describe('parallelViewLeftLineType', () => {
    it(`should return ${OLD_NO_NEW_LINE_TYPE}`, () => {
      expect(
        utils.parallelViewLeftLineType({ line: { right: { type: NEW_NO_NEW_LINE_TYPE } } }),
      ).toEqual(OLD_NO_NEW_LINE_TYPE);
    });

    it(`should return 'new'`, () => {
      expect(utils.parallelViewLeftLineType({ line: { left: { type: 'new' } } })[0]).toBe('new');
    });

    it(`should return ${EMPTY_CELL_TYPE}`, () => {
      expect(utils.parallelViewLeftLineType({})).toContain(EMPTY_CELL_TYPE);
    });

    it(`should return hll:true`, () => {
      expect(utils.parallelViewLeftLineType({ highlighted: true })[1].hll).toBe(true);
    });
  });

  describe('shouldShowCommentButton', () => {
    it.each`
      hover    | context  | meta     | discussions | expectation
      ${true}  | ${false} | ${false} | ${false}    | ${true}
      ${false} | ${false} | ${false} | ${false}    | ${false}
      ${true}  | ${true}  | ${false} | ${false}    | ${false}
      ${true}  | ${true}  | ${true}  | ${false}    | ${false}
      ${true}  | ${true}  | ${true}  | ${true}     | ${false}
    `(
      'should return $expectation when hover is $hover',
      ({ hover, context, meta, discussions, expectation }) => {
        expect(utils.shouldShowCommentButton(hover, context, meta, discussions)).toBe(expectation);
      },
    );
  });

  describe('mapParallel', () => {
    it('should assign computed properties to the line object', () => {
      const side = {
        discussions: [{}],
        discussionsExpanded: true,
        hasForm: true,
        problems: problemsClone(),
      };
      const content = {
        diffFile: {},
        hasParallelDraftLeft: () => false,
        hasParallelDraftRight: () => false,
        draftsForLine: () => [],
      };
      const line = { left: side, right: side };
      const expectation = {
        commentRowClasses: '',
        draftRowClasses: 'js-temp-notes-holder',
        hasDiscussionsLeft: true,
        hasDiscussionsRight: true,
        isContextLineLeft: false,
        isContextLineRight: false,
        isMatchLineLeft: false,
        isMatchLineRight: false,
        isMetaLineLeft: false,
        isMetaLineRight: false,
      };
      const leftExpectation = {
        renderDiscussion: true,
        hasDraft: false,
        lineDrafts: [],
        hasCommentForm: true,
      };
      const rightExpectation = {
        renderDiscussion: false,
        hasDraft: false,
        lineDrafts: [],
        hasCommentForm: false,
      };
      const mapped = utils.mapParallel(content)(line);

      expect(mapped).toMatchObject(expectation);
      expect(mapped.left).toMatchObject(leftExpectation);
      expect(mapped.right).toMatchObject(rightExpectation);
    });
  });
});
