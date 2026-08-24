import { setHTMLFixture } from 'helpers/fixtures';
import {
  calculateBlameOffset,
  shouldRender,
  toggleBlameLineBorders,
  hasBlameDataForChunk,
  normalizeBlameGroups,
  blameGroupsForChunk,
} from '~/vue_shared/components/source_viewer/utils';
import { SOURCE_CODE_CONTENT_MOCK, BLAME_DATA_MOCK } from './mock_data';

describe('SourceViewer utils', () => {
  beforeEach(() => setHTMLFixture(SOURCE_CODE_CONTENT_MOCK));

  const findContent = () => document.querySelector('.content');

  describe('calculateBlameOffset', () => {
    it('returns an offset of zero if line number === 1', () => {
      expect(calculateBlameOffset(1)).toBe('0px');
    });

    it('calculates an offset for the blame component', () => {
      const { offsetTop } = document.querySelector('#LC3');
      expect(calculateBlameOffset(3)).toBe(`${offsetTop}px`);
    });

    it('returns null when the line content element is not in the DOM', () => {
      expect(calculateBlameOffset(999)).toBeNull();
    });
  });

  describe('shouldRender', () => {
    const commit = { sha: 'abc' };
    const identicalSha = [{ commit }, { commit }];

    it.each`
      data            | index | result
      ${identicalSha} | ${0}  | ${true}
      ${identicalSha} | ${1}  | ${false}
    `('returns $result', ({ data, index, result }) => {
      expect(shouldRender(data, index)).toBe(result);
    });
  });

  describe('toggleBlameLineBorders', () => {
    it('adds classes', () => {
      toggleBlameLineBorders(BLAME_DATA_MOCK, true);
      expect(findContent()).toMatchSnapshot();
    });

    it('removes classes', () => {
      toggleBlameLineBorders(BLAME_DATA_MOCK, false);
      expect(findContent()).toMatchSnapshot();
    });
  });

  describe('hasBlameDataForChunk', () => {
    const chunk = { startingFrom: 0, totalLines: 70 };

    it.each([
      [[{ lineno: 1 }], true, 'within range'],
      [[{ lineno: 70 }], true, 'at boundary'],
      [[{ lineno: 71 }], false, 'outside range'],
      [[], false, 'empty'],
    ])('returns %s when blame data is %s', (blameData, expected) => {
      expect(hasBlameDataForChunk(blameData, chunk)).toBe(expected);
    });

    it('handles chunk with non-zero startingFrom', () => {
      const chunk2 = { startingFrom: 70, totalLines: 40 };
      expect(hasBlameDataForChunk([{ lineno: 80 }], chunk2)).toBe(true);
    });
  });

  describe('normalizeBlameGroups', () => {
    const groupA = { lineno: 1, span: 2, commit: { sha: 'a' } };
    const groupB = { lineno: 3, span: 1, commit: { sha: 'b' } };

    it('sorts groups that arrived out of order', () => {
      expect(normalizeBlameGroups([groupB, groupA])).toEqual([groupA, groupB]);
    });

    it('merges consecutive groups for the same commit into one span', () => {
      const firstHalf = { lineno: 1, span: 2, commit: { sha: 'a' } };
      const secondHalf = { lineno: 3, span: 4, commit: { sha: 'a' } };

      expect(normalizeBlameGroups([firstHalf, secondHalf])).toEqual([
        { lineno: 1, span: 6, commit: { sha: 'a' } },
      ]);
    });

    it('does not merge the same commit when the lines are not contiguous', () => {
      const early = { lineno: 1, span: 1, commit: { sha: 'a' } };
      const later = { lineno: 9, span: 1, commit: { sha: 'a' } };

      expect(normalizeBlameGroups([early, later])).toEqual([early, later]);
    });

    it('defaults a missing span to a single line', () => {
      expect(normalizeBlameGroups([{ lineno: 5, commit: { sha: 'a' } }])).toEqual([
        { lineno: 5, span: 1, commit: { sha: 'a' } },
      ]);
    });

    it('absorbs a group that was delivered twice', () => {
      // The copy is a distinct object, matching a repeat Apollo read that hands
      // back a fresh tree — which a reference-equality check cannot catch.
      const group = { lineno: 1, span: 2, commit: { sha: 'a' } };

      expect(normalizeBlameGroups([group, { ...group }])).toEqual([group]);
    });

    it('keeps the longer span when a duplicate reports more lines', () => {
      const short = { lineno: 1, span: 2, commit: { sha: 'a' } };
      const long = { lineno: 1, span: 5, commit: { sha: 'a' } };

      expect(normalizeBlameGroups([short, long])).toEqual([
        { lineno: 1, span: 5, commit: { sha: 'a' } },
      ]);
    });

    it('is idempotent', () => {
      const once = normalizeBlameGroups([groupA, groupB, { ...groupA }, { ...groupB }]);

      expect(normalizeBlameGroups(once)).toEqual(once);
      expect(once).toEqual([groupA, groupB]);
    });

    it('does not merge a duplicate of a different commit', () => {
      const mine = { lineno: 1, span: 2, commit: { sha: 'a' } };
      const theirs = { lineno: 1, span: 2, commit: { sha: 'b' } };

      expect(normalizeBlameGroups([mine, theirs])).toHaveLength(2);
    });

    it('does not mutate the input', () => {
      const input = [{ lineno: 1, span: 2, commit: { sha: 'a' } }];
      normalizeBlameGroups([...input, { lineno: 3, span: 1, commit: { sha: 'a' } }]);

      expect(input[0].span).toBe(2);
    });
  });

  describe('blameGroupsForChunk', () => {
    const chunk = { startingFrom: 70, totalLines: 40 };

    it('maps a group inside the chunk to 1-based grid rows', () => {
      const groups = [{ lineno: 71, span: 3, commit: { sha: 'a' } }];

      expect(blameGroupsForChunk(groups, chunk)).toEqual([
        expect.objectContaining({ rowStart: 1, rowSpan: 3, hasSeparator: true }),
      ]);
    });

    it('excludes groups that fall outside the chunk', () => {
      const groups = [
        { lineno: 1, span: 5, commit: { sha: 'a' } },
        { lineno: 200, span: 1, commit: { sha: 'b' } },
      ];

      expect(blameGroupsForChunk(groups, chunk)).toEqual([]);
    });

    it('clamps a group that runs past the end of the chunk', () => {
      const groups = [{ lineno: 109, span: 20, commit: { sha: 'a' } }];

      expect(blameGroupsForChunk(groups, chunk)).toEqual([
        expect.objectContaining({ rowStart: 39, rowSpan: 2 }),
      ]);
    });

    it('clamps a group that started before the chunk and marks it a continuation', () => {
      const groups = [{ lineno: 65, span: 10, commit: { sha: 'a' } }];

      expect(blameGroupsForChunk(groups, chunk)).toEqual([
        expect.objectContaining({ rowStart: 1, rowSpan: 4, hasSeparator: false }),
      ]);
    });

    it('includes a group covering the chunk boundary lines exactly', () => {
      const groups = [{ lineno: 110, span: 1, commit: { sha: 'a' } }];

      expect(blameGroupsForChunk(groups, chunk)).toEqual([
        expect.objectContaining({ rowStart: 40, rowSpan: 1 }),
      ]);
    });

    it('gives the block on the first line of the file no separator', () => {
      const firstChunk = { startingFrom: 0, totalLines: 70 };
      const groups = [
        { lineno: 1, span: 2, commit: { sha: 'a' } },
        { lineno: 3, span: 1, commit: { sha: 'b' } },
      ];

      expect(blameGroupsForChunk(groups, firstChunk)).toEqual([
        expect.objectContaining({ rowStart: 1, hasSeparator: false }),
        expect.objectContaining({ rowStart: 3, hasSeparator: true }),
      ]);
    });
  });
});
