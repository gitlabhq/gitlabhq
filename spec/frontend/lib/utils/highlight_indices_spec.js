import { getHighlightIndices, buildSegments } from '~/lib/utils/highlight_indices';

describe('getHighlightIndices', () => {
  describe('when text or match is empty', () => {
    it('returns empty set for empty text', () => {
      expect(getHighlightIndices('', 'test')).toEqual(new Set());
    });

    it('returns empty set for empty match', () => {
      expect(getHighlightIndices('gitlab', '')).toEqual(new Set());
    });

    it('returns empty set when both are empty', () => {
      expect(getHighlightIndices('', '')).toEqual(new Set());
    });
  });

  describe('fuzzy mode (default)', () => {
    it('returns indices for fuzzy matched characters', () => {
      const indices = getHighlightIndices('gitlab', 'it');
      expect(indices.has(1)).toBe(true); // 'i'
      expect(indices.has(2)).toBe(true); // 't'
      expect(indices.size).toBe(2);
    });

    it('returns empty set when no fuzzy match is found', () => {
      expect(getHighlightIndices('gitlab', 'zzz').size).toBe(0);
    });

    it('handles special characters in match without errors', () => {
      expect(() => getHighlightIndices('test()', '()')).not.toThrow();
    });
  });

  describe('global mode', () => {
    it('returns indices for all occurrences of the substring', () => {
      const indices = getHighlightIndices('lib/utils/lib_helper.js', 'lib', { global: true });
      // First 'lib' at 0,1,2 and second 'lib' at 10,11,12
      expect(indices).toEqual(new Set([0, 1, 2, 10, 11, 12]));
    });

    it('returns empty set when substring is not found', () => {
      expect(getHighlightIndices('gitlab', 'zzz', { global: true }).size).toBe(0);
    });

    it('handles single occurrence', () => {
      const indices = getHighlightIndices('hello world', 'world', { global: true });
      expect(indices).toEqual(new Set([6, 7, 8, 9, 10]));
    });

    it('is case-sensitive', () => {
      const indices = getHighlightIndices('Controller/controller', 'controller', { global: true });
      expect(indices).toEqual(new Set([11, 12, 13, 14, 15, 16, 17, 18, 19, 20]));
    });

    it('handles adjacent occurrences', () => {
      const indices = getHighlightIndices('aaa', 'a', { global: true });
      expect(indices).toEqual(new Set([0, 1, 2]));
    });

    it('handles special regex characters safely', () => {
      const indices = getHighlightIndices('test+file(1)', 'test+', { global: true });
      expect(indices).toEqual(new Set([0, 1, 2, 3, 4]));
    });
  });
});

describe('buildSegments', () => {
  it('returns single unhighlighted segment for empty indices', () => {
    expect(buildSegments('gitlab', new Set())).toEqual([{ text: 'gitlab', highlight: false }]);
  });

  it('returns empty array for empty text', () => {
    expect(buildSegments('', new Set())).toEqual([]);
  });

  it('merges consecutive highlighted characters into one segment', () => {
    const indices = new Set([0, 1, 2]);
    expect(buildSegments('gitlab', indices)).toEqual([
      { text: 'git', highlight: true },
      { text: 'lab', highlight: false },
    ]);
  });

  it('merges consecutive unhighlighted characters into one segment', () => {
    const indices = new Set([3]);
    expect(buildSegments('gitlab', indices)).toEqual([
      { text: 'git', highlight: false },
      { text: 'l', highlight: true },
      { text: 'ab', highlight: false },
    ]);
  });

  it('handles all characters highlighted', () => {
    const indices = new Set([0, 1, 2, 3]);
    expect(buildSegments('test', indices)).toEqual([{ text: 'test', highlight: true }]);
  });

  it('handles alternating highlight states', () => {
    const indices = new Set([0, 2, 4]);
    expect(buildSegments('abcde', indices)).toEqual([
      { text: 'a', highlight: true },
      { text: 'b', highlight: false },
      { text: 'c', highlight: true },
      { text: 'd', highlight: false },
      { text: 'e', highlight: true },
    ]);
  });
});
