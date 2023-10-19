import { convertEnvironmentScope, mapEnvironmentNames } from '~/ci/ci_variable_list/utils';
import { allEnvironments } from '~/ci/ci_variable_list/constants';

describe('utils', () => {
  describe('convertEnvironmentScope', () => {
    it('converts the * to the `All environments` text', () => {
      expect(convertEnvironmentScope('*')).toBe(allEnvironments.text);
    });

    it('returns the environment as is if not the *', () => {
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
