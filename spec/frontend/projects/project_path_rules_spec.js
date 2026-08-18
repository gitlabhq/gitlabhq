import {
  checkRules,
  START_RULE,
  CONTAINS_RULE,
  END_RULE,
  SEPARATOR_RULE,
  SUFFIX_RULE,
} from '~/projects/project_path_rules';

describe('checkRules', () => {
  it('returns an empty string for an empty path', () => {
    expect(checkRules('')).toBe('');
  });

  it.each([
    ['my-awesome-project'],
    ['project_with_underscores'],
    ['project.with.periods'],
    ['1abc'],
    ['a'],
    ['ab'],
  ])('returns an empty string for valid path %p', (path) => {
    expect(checkRules(path)).toBe('');
  });

  describe('start rule', () => {
    it.each([['-abc'], ['-'], ['-1'], ['_abc'], ['.abc']])(
      'returns the start-rule message for %p',
      (path) => {
        expect(checkRules(path)).toBe(START_RULE.message);
      },
    );
  });

  describe('contains rule', () => {
    it.each([['abc!'], ['ab cd'], ['ab$cd'], ['ab/cd']])(
      'returns the contains-rule message for %p',
      (path) => {
        expect(checkRules(path)).toBe(CONTAINS_RULE.message);
      },
    );
  });

  describe('end rule', () => {
    it.each([['abc-'], ['abc.'], ['abc_']])('returns the end-rule message for %p', (path) => {
      expect(checkRules(path)).toBe(END_RULE.message);
    });
  });

  describe('separator rule', () => {
    it.each([['a--b'], ['a..b'], ['a__b'], ['a-_b'], ['a._b']])(
      'returns the separator-rule message for %p',
      (path) => {
        expect(checkRules(path)).toBe(SEPARATOR_RULE.message);
      },
    );
  });

  describe('suffix rule', () => {
    it.each([['repo.git'], ['feed.atom']])('returns the suffix-rule message for %p', (path) => {
      expect(checkRules(path)).toBe(SUFFIX_RULE.message);
    });

    it.each([['repo.GIT'], ['feed.ATOM'], ['repo.Git']])(
      'does not flag mixed-case suffixes that the backend allows: %p',
      (path) => {
        expect(checkRules(path)).toBe('');
      },
    );
  });

  it('prioritises the start-rule message when multiple rules fail', () => {
    expect(checkRules('-abc!')).toBe(START_RULE.message);
  });

  describe('surrounding whitespace', () => {
    it.each([[' a '], ['  my-awesome-project'], ['my-awesome-project\t']])(
      'ignores whitespace the form trims on submit: %p',
      (path) => {
        expect(checkRules(path)).toBe('');
      },
    );

    it('returns an empty string for a whitespace-only path', () => {
      expect(checkRules('   ')).toBe('');
    });

    it('still reports the violated rule for a padded invalid path', () => {
      expect(checkRules(' -bad ')).toBe(START_RULE.message);
    });
  });
});
