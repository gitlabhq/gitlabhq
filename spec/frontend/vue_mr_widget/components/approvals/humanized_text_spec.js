import { humanizeInvalidApproversRules } from '~/vue_merge_request_widget/components/approvals/humanized_text';

const testRules = [{ name: 'Lorem' }, { name: 'Ipsum' }, { name: 'Dolar' }];

describe('humanizeInvalidApproversRules', () => {
  it('returns text in regards to a single rule', () => {
    const [singleRule] = testRules;
    expect(humanizeInvalidApproversRules([singleRule])).toBe('"Lorem"');
  });

  it('returns empty text when there is no rule', () => {
    expect(humanizeInvalidApproversRules([])).toBe('');
  });

  it('returns text in regards to multiple rules', () => {
    expect(humanizeInvalidApproversRules(testRules)).toBe('"Lorem", "Ipsum" and "Dolar"');
  });
});
