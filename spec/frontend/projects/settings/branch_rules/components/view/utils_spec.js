import { findSelectedOptionValueByLabel } from '~/projects/settings/branch_rules/components/view/utils';

describe('utils', () => {
  describe('findSelectedOptionValueByLabel', () => {
    const options = [
      { label: 'Option 1', value: 'value1' },
      { label: 'Option 2', value: 'value2' },
      { label: 'Option 3', value: 'value3' },
    ];

    it('returns the value when option with matching value is found', () => {
      expect(findSelectedOptionValueByLabel(options, 'Option 2')).toBe('value2');
    });

    it('returns first option value when no option with matching value is found', () => {
      expect(findSelectedOptionValueByLabel(options, 'non-existent-label')).toBe('value1');
    });

    it('returns undefined when options array is empty', () => {
      const emptyOptions = [];
      expect(findSelectedOptionValueByLabel(emptyOptions, 'value1')).toBeUndefined();
    });
  });
});
