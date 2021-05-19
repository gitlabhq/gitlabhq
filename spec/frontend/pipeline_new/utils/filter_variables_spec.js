import filterVariables from '~/pipeline_new/utils/filter_variables';
import { mockVariables } from '../mock_data';

describe('Filter variables utility function', () => {
  it('filters variables that do not contain a key', () => {
    const expectedVaraibles = [
      {
        variable_type: 'env_var',
        key: 'var_without_value',
        secret_value: '',
      },
      {
        variable_type: 'env_var',
        key: 'var_with_value',
        secret_value: 'test_value',
      },
    ];

    expect(filterVariables(mockVariables)).toEqual(expectedVaraibles);
  });
});
