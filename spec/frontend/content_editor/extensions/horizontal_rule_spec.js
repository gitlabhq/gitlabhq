import { hrInputRuleRegExp } from '~/content_editor/extensions/horizontal_rule';

describe('content_editor/extensions/horizontal_rule', () => {
  describe.each`
    input      | matches
    ${'---'}   | ${true}
    ${'--'}    | ${false}
    ${'---x'}  | ${false}
    ${' ---x'} | ${false}
    ${' --- '} | ${false}
    ${'x---x'} | ${false}
    ${'x---'}  | ${false}
  `('hrInputRuleRegExp', ({ input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'}: "${input}"`, () => {
      const match = new RegExp(hrInputRuleRegExp).test(input);

      expect(match).toBe(matches);
    });
  });
});
