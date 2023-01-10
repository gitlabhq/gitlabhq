import {
  createJoinedEnvironments,
  convertEnvironmentScope,
  mapEnvironmentNames,
} from '~/ci/ci_variable_list/utils';
import { allEnvironments } from '~/ci/ci_variable_list/constants';

describe('utils', () => {
  const environments = ['dev', 'prod'];
  const newEnvironments = ['staging'];

  describe('createJoinedEnvironments', () => {
    it('returns only `environments` if `variables` argument is undefined', () => {
      const variables = undefined;

      expect(createJoinedEnvironments(variables, environments, [])).toEqual(environments);
    });

    it('returns a list of environments and environment scopes taken from variables in alphabetical order', () => {
      const envScope1 = 'new1';
      const envScope2 = 'new2';

      const variables = [{ environmentScope: envScope1 }, { environmentScope: envScope2 }];

      expect(createJoinedEnvironments(variables, environments, [])).toEqual([
        environments[0],
        envScope1,
        envScope2,
        environments[1],
      ]);
    });

    it('returns combined list with new environments included', () => {
      const variables = undefined;

      expect(createJoinedEnvironments(variables, environments, newEnvironments)).toEqual([
        ...environments,
        ...newEnvironments,
      ]);
    });

    it('removes duplicate environments', () => {
      const envScope1 = environments[0];
      const envScope2 = 'new2';

      const variables = [{ environmentScope: envScope1 }, { environmentScope: envScope2 }];

      expect(createJoinedEnvironments(variables, environments, [])).toEqual([
        environments[0],
        envScope2,
        environments[1],
      ]);
    });
  });

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
