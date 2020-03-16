import {
  prepareDataForDisplay,
  prepareEnvironments,
  prepareDataForApi,
} from '~/ci_variable_list/store/utils';
import mockData from '../services/mock_data';

describe('CI variables store utils', () => {
  it('prepares ci variables for display', () => {
    expect(prepareDataForDisplay(mockData.mockVariablesApi)).toStrictEqual(
      mockData.mockVariablesDisplay,
    );
  });

  it('prepares single ci variable for api', () => {
    expect(prepareDataForApi(mockData.mockVariablesDisplay[0])).toStrictEqual({
      environment_scope: '*',
      id: 113,
      key: 'test_var',
      masked: 'false',
      protected: 'false',
      secret_value: 'test_val',
      value: 'test_val',
      variable_type: 'env_var',
    });

    expect(prepareDataForApi(mockData.mockVariablesDisplay[1])).toStrictEqual({
      environment_scope: '*',
      id: 114,
      key: 'test_var_2',
      masked: 'false',
      protected: 'false',
      secret_value: 'test_val_2',
      value: 'test_val_2',
      variable_type: 'file',
    });
  });

  it('prepares single ci variable for delete', () => {
    expect(prepareDataForApi(mockData.mockVariablesDisplay[0], true)).toHaveProperty(
      '_destroy',
      true,
    );
  });

  it('prepares environments for display', () => {
    expect(prepareEnvironments(mockData.mockEnvironments)).toStrictEqual(['staging', 'production']);
  });
});
