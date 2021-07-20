import * as utils from '~/diffs/components/diff_row_utils';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
} from '~/diffs/constants';

const LINE_CODE = 'abc123';

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
    expect(utils.lineHref({ line_code: LINE_CODE })).toEqual(`#${LINE_CODE}`);
  });

  it(`should return '#' if line is undefined`, () => {
    expect(utils.lineHref()).toEqual('#');
  });

  it(`should return '#' if line_code is undefined`, () => {
    expect(utils.lineHref({})).toEqual('#');
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
    line               | hll      | isLoggedIn | isHover  | expectation
    ${undefined}       | ${true}  | ${true}    | ${true}  | ${[]}
    ${{ type: 'new' }} | ${false} | ${false}   | ${false} | ${['new', { hll: false, 'is-over': false, new_line: true, old_line: false }]}
    ${{ type: 'new' }} | ${true}  | ${true}    | ${false} | ${['new', { hll: true, 'is-over': false, new_line: true, old_line: false }]}
    ${{ type: 'new' }} | ${true}  | ${false}   | ${true}  | ${['new', { hll: true, 'is-over': false, new_line: true, old_line: false }]}
    ${{ type: 'new' }} | ${true}  | ${true}    | ${true}  | ${['new', { hll: true, 'is-over': true, new_line: true, old_line: false }]}
  `('should return $expectation', ({ line, hll, isLoggedIn, isHover, expectation }) => {
    const classes = utils.classNameMapCell({ line, hll, isLoggedIn, isHover });
    expect(classes).toEqual(expectation);
  });
});

describe('addCommentTooltip', () => {
  const brokenSymLinkTooltip =
    'Commenting on symbolic links that replace or are replaced by files is currently not supported.';
  const brokenRealTooltip =
    'Commenting on files that replace or are replaced by symbolic links is currently not supported.';
  const dragTooltip = 'Add a comment to this line or drag for multiple lines';

  it('should return default tooltip', () => {
    expect(utils.addCommentTooltip()).toBeUndefined();
  });

  it('should return drag comment tooltip when dragging is enabled', () => {
    expect(utils.addCommentTooltip({})).toEqual(dragTooltip);
  });

  it('should return broken symlink tooltip', () => {
    expect(utils.addCommentTooltip({ commentsDisabled: { wasSymbolic: true } })).toEqual(
      brokenSymLinkTooltip,
    );
    expect(utils.addCommentTooltip({ commentsDisabled: { isSymbolic: true } })).toEqual(
      brokenSymLinkTooltip,
    );
  });

  it('should return broken real tooltip', () => {
    expect(utils.addCommentTooltip({ commentsDisabled: { wasReal: true } })).toEqual(
      brokenRealTooltip,
    );
    expect(utils.addCommentTooltip({ commentsDisabled: { isReal: true } })).toEqual(
      brokenRealTooltip,
    );
  });
});

describe('parallelViewLeftLineType', () => {
  it(`should return ${OLD_NO_NEW_LINE_TYPE}`, () => {
    expect(utils.parallelViewLeftLineType({ right: { type: NEW_NO_NEW_LINE_TYPE } })).toEqual(
      OLD_NO_NEW_LINE_TYPE,
    );
  });

  it(`should return 'new'`, () => {
    expect(utils.parallelViewLeftLineType({ left: { type: 'new' } })).toContain('new');
  });

  it(`should return ${EMPTY_CELL_TYPE}`, () => {
    expect(utils.parallelViewLeftLineType({})).toContain(EMPTY_CELL_TYPE);
  });

  it(`should return hll:true`, () => {
    expect(utils.parallelViewLeftLineType({}, true)[1]).toEqual({ hll: true });
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
    };
    const content = {
      diffFile: {},
      hasParallelDraftLeft: () => false,
      hasParallelDraftRight: () => false,
      draftForLine: () => ({}),
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
      lineDraft: {},
      hasCommentForm: true,
    };
    const rightExpectation = {
      renderDiscussion: false,
      hasDraft: false,
      lineDraft: {},
      hasCommentForm: false,
    };
    const mapped = utils.mapParallel(content)(line);

    expect(mapped).toMatchObject(expectation);
    expect(mapped.left).toMatchObject(leftExpectation);
    expect(mapped.right).toMatchObject(rightExpectation);
  });
});
