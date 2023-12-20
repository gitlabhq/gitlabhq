import {
  convertEnvironmentScope,
  mapEnvironmentNames,
} from '~/ci/common/private/ci_environments_dropdown';

describe('utils', () => {
  describe('convertEnvironmentScope', () => {
    it('converts the * to the `All environments` text', () => {
      expect(convertEnvironmentScope('*')).toBe('All (default)');
    });

    it('converts the `Not applicable` to the `Not applicable`', () => {
      expect(convertEnvironmentScope('Not applicable')).toBe('Not applicable');
    });

    it('returns other environments as-is', () => {
      expect(convertEnvironmentScope('prod')).toBe('prod');
    });
  });

  describe('mapEnvironmentNames', () => {
    const envName = 'dev';
    const envName2 = 'prod';

    const nodes = [
      { name: envName, otherProp: {} },
      { name: envName2, otherProp: {} },
    ];
    it('flatten a nodes array with only their names', () => {
      expect(mapEnvironmentNames(nodes)).toEqual([envName, envName2]);
    });
  });
});
