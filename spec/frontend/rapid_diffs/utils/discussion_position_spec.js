import {
  getDiscussionPositions,
  isFileDiscussion,
  isImageDiscussion,
  isLineDiscussion,
  positionMatchesDiffRefs,
  positionMatchesFilePath,
  positionMatchesLine,
  findApplicablePosition,
  discussionMatchesLinePosition,
} from '~/rapid_diffs/utils/discussion_position';

describe('discussion_position utils', () => {
  const diffRefs = { base_sha: 'base', head_sha: 'head', start_sha: 'start' };
  const otherRefs = { base_sha: 'x', head_sha: 'y', start_sha: 'z' };
  const pos = (overrides = {}) => ({
    old_path: 'a.js',
    new_path: 'a.js',
    old_line: 5,
    new_line: 10,
    ...diffRefs,
    ...overrides,
  });

  describe('getDiscussionPositions', () => {
    it('yields original_position, position, and positions in order', () => {
      const orig = pos({ old_line: 1 });
      const current = pos({ old_line: 2 });
      const extra = pos({ old_line: 3 });

      const result = [
        ...getDiscussionPositions({
          original_position: orig,
          position: current,
          positions: [extra],
        }),
      ];

      expect(result).toEqual([orig, current, extra]);
    });

    it('skips missing fields', () => {
      const current = pos();

      expect([...getDiscussionPositions({ position: current })]).toEqual([current]);
    });

    it('yields nothing for empty discussion', () => {
      expect([...getDiscussionPositions({})]).toEqual([]);
    });
  });

  describe('positionMatchesDiffRefs', () => {
    it('returns true when all three SHAs match', () => {
      expect(positionMatchesDiffRefs(pos(), diffRefs)).toBe(true);
    });

    it.each(['base_sha', 'head_sha', 'start_sha'])('returns false when %s differs', (key) => {
      expect(positionMatchesDiffRefs(pos({ [key]: 'mismatch' }), diffRefs)).toBe(false);
    });
  });

  describe('positionMatchesFilePath', () => {
    it('returns true when both paths match', () => {
      expect(positionMatchesFilePath(pos(), { oldPath: 'a.js', newPath: 'a.js' })).toBe(true);
    });

    it.each([
      ['old_path', { oldPath: 'b.js', newPath: 'a.js' }],
      ['new_path', { oldPath: 'a.js', newPath: 'b.js' }],
    ])('returns false when %s differs', (_, paths) => {
      expect(positionMatchesFilePath(pos(), paths)).toBe(false);
    });
  });

  describe('positionMatchesLine', () => {
    const linePos = { oldPath: 'a.js', newPath: 'a.js', oldLine: 5, newLine: 10 };

    it('returns true when paths and lines match', () => {
      expect(positionMatchesLine(pos(), linePos)).toBe(true);
    });

    it.each([
      ['old_line', { old_line: 99 }],
      ['new_line', { new_line: 99 }],
      ['old_path', { old_path: 'b.js' }],
      ['new_path', { new_path: 'b.js' }],
    ])('returns false when %s differs', (_, override) => {
      expect(positionMatchesLine(pos(override), linePos)).toBe(false);
    });
  });

  describe.each([
    ['isFileDiscussion', isFileDiscussion, 'file'],
    ['isLineDiscussion', isLineDiscussion, 'text'],
    ['isImageDiscussion', isImageDiscussion, 'image'],
  ])('%s', (_, fn, type) => {
    it(`returns true for position_type ${type}`, () => {
      expect(fn({ position: { position_type: type } })).toBe(true);
    });

    it('returns false otherwise', () => {
      expect(fn({ position: { position_type: 'other' } })).toBe(false);
      expect(fn({})).toBe(false);
    });
  });

  describe('findApplicablePosition', () => {
    it.each([
      ['original_position', { original_position: pos(), position: pos(otherRefs) }],
      ['position', { original_position: pos(otherRefs), position: pos() }],
      [
        'positions array',
        { original_position: pos(otherRefs), position: pos(otherRefs), positions: [pos()] },
      ],
    ])('returns a match from %s', (_, discussion) => {
      expect(positionMatchesDiffRefs(findApplicablePosition(discussion, diffRefs), diffRefs)).toBe(
        true,
      );
    });

    it('returns undefined when no position matches', () => {
      expect(
        findApplicablePosition(
          { original_position: pos(otherRefs), position: pos(otherRefs) },
          diffRefs,
        ),
      ).toBeUndefined();
    });
  });

  describe('discussionMatchesLinePosition', () => {
    const linePos = { oldPath: 'a.js', newPath: 'a.js', oldLine: 5, newLine: 10 };

    it.each([
      ['matches current position', { position: pos() }, true],
      [
        'matches via original_position',
        { original_position: pos(), position: pos(otherRefs) },
        true,
      ],
      ['rejects wrong SHAs', { position: pos(otherRefs) }, false],
      ['rejects wrong line', { position: pos({ old_line: 99 }) }, false],
    ])('%s', (_, discussion, expected) => {
      expect(discussionMatchesLinePosition(discussion, linePos, diffRefs)).toBe(expected);
    });
  });
});
