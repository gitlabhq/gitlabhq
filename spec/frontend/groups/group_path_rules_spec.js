import { validateGroupPath } from '~/groups/group_path_rules';

describe('validateGroupPath', () => {
  it('returns the required message for an empty path', () => {
    expect(validateGroupPath('')).toBe('Group URL is required.');
  });

  it.each([
    ['my-awesome-group'],
    ['group_with_underscores'],
    ['group.with.periods'],
    ['1abc'],
    ['_abc'],
    ['.abc'],
    ['ab'],
  ])('returns null for valid path %p', (path) => {
    expect(validateGroupPath(path)).toBe(null);
  });

  describe('start rule', () => {
    it.each([['-abc'], ['-'], ['-1']])('returns the start-rule message for %p', (path) => {
      expect(validateGroupPath(path)).toBe(
        'Group URL must start with a letter, digit, underscore, or period.',
      );
    });
  });

  describe('contains rule', () => {
    it.each([['abc!'], ['ab cd'], ['ab$cd'], ['ab/cd']])(
      'returns the contains-rule message for %p',
      (path) => {
        expect(validateGroupPath(path)).toBe(
          'Group URL can only contain letters, digits, underscores, periods, and dashes.',
        );
      },
    );
  });

  describe('end rule', () => {
    it.each([['abc.'], ['ab.'], ['abc..']])('returns the end-rule message for %p', (path) => {
      expect(validateGroupPath(path)).toBe(
        'Group URL must end with a letter, digit, underscore, or dash.',
      );
    });

    it('accepts a path that ends with a dash (matches backend rules)', () => {
      expect(validateGroupPath('abc-')).toBe(null);
    });
  });

  describe('suffix rule', () => {
    it.each([['repo.git'], ['feed.atom'], ['repo.GIT'], ['feed.ATOM'], ['repo.Git']])(
      'returns the suffix-rule message for %p',
      (path) => {
        expect(validateGroupPath(path)).toBe('Group URL must not end with `.git` or `.atom`.');
      },
    );
  });

  describe('minimum length rule', () => {
    it('returns the minimum-length message for a single character path', () => {
      expect(validateGroupPath('a')).toBe('Group URL must be at least 2 characters long.');
    });
  });

  it('prioritises the start-rule message when multiple rules fail', () => {
    expect(validateGroupPath('-abc!')).toBe(
      'Group URL must start with a letter, digit, underscore, or period.',
    );
  });
});
