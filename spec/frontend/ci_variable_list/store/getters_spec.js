import * as getters from '~/ci_variable_list/store/getters';
import mockData from '../services/mock_data';

describe('Ci variable getters', () => {
  describe('joinedEnvironments', () => {
    it('should join fetched environments with variable environment scopes', () => {
      const state = {
        environments: ['All (default)', 'staging', 'deployment', 'prod'],
        variables: mockData.mockVariableScopes,
      };

      expect(getters.joinedEnvironments(state)).toEqual([
        'All (default)',
        'deployment',
        'prod',
        'production',
        'staging',
      ]);
    });
  });
});
