import { checkGroupNameRules } from '~/groups/group_name_rules';

describe('checkGroupNameRules', () => {
  it('returns the required message for an empty name', () => {
    expect(checkGroupNameRules('')).toBe('Group name is required.');
  });

  it.each([
    ['My Group'],
    ['group_with_underscores'],
    ['group.with.periods'],
    ['group-with-dashes'],
    ['Group (with parens)'],
    ['🚀 rocket'],
    ['_underscore'],
    ['123abc'],
    ['équipe'],
    ['東京'],
    ['Über Gruppe'],
  ])('returns null for valid name %p', (name) => {
    expect(checkGroupNameRules(name)).toBe(null);
  });

  describe('start rule', () => {
    it.each([['-abc'], ['.abc'], [' leading space'], ['(parens first)']])(
      'returns the start-rule message for %p',
      (name) => {
        expect(checkGroupNameRules(name)).toBe(
          'Group name must start with a letter, digit, emoji, or underscore.',
        );
      },
    );
  });

  describe('contains rule', () => {
    it.each([['abc!'], ['ab/cd'], ['ab$cd'], ['ab@cd']])(
      'returns the contains-rule message for %p',
      (name) => {
        expect(checkGroupNameRules(name)).toBe(
          'Group name can contain only letters, digits, dashes, spaces, dots, underscores, parenthesis, and emojis.',
        );
      },
    );
  });

  it('prioritises the start-rule message when multiple rules fail', () => {
    expect(checkGroupNameRules('-abc!')).toBe(
      'Group name must start with a letter, digit, emoji, or underscore.',
    );
  });
});
