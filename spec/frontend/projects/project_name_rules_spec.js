import { checkRules } from '~/projects/project_name_rules';

describe('checkRules', () => {
  it.each([[''], ['   ']])('returns the required message for %p', (name) => {
    expect(checkRules(name)).toBe('Project name is required.');
  });

  it.each([
    ['My Project'],
    ['project_with_underscores'],
    ['project.with.periods'],
    ['project-with-dashes'],
    ['project+with+pluses'],
    ['🚀 rocket'],
    ['_underscore'],
    ['123abc'],
    ['équipe'],
    ['東京'],
    ['Über Projekt'],
  ])('returns empty string for valid name %p', (name) => {
    expect(checkRules(name)).toBe('');
  });

  describe('start rule', () => {
    it.each([['-abc'], ['.abc'], [' leading space'], ['+plus first']])(
      'returns the start-rule message for %p',
      (name) => {
        expect(checkRules(name)).toBe(
          'Project name must start with a letter, digit, basic emoji, or underscore.',
        );
      },
    );
  });

  describe('contains rule', () => {
    it.each([['abc!'], ['ab/cd'], ['ab$cd'], ['ab@cd'], ['ab(cd)']])(
      'returns the contains-rule message for %p',
      (name) => {
        expect(checkRules(name)).toBe(
          'Project name can contain only lowercase or uppercase letters, digits, basic emoji, spaces, dots, underscores, dashes, or pluses.',
        );
      },
    );
  });

  it('prioritises the start-rule message when multiple rules fail', () => {
    expect(checkRules('-abc!')).toBe(
      'Project name must start with a letter, digit, basic emoji, or underscore.',
    );
  });
});
