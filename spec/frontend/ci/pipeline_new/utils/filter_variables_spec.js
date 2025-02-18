import filterVariables from '~/ci/pipeline_new/utils/filter_variables';
import { mockVariables } from '../mock_data';

describe('Filter variables utility function', () => {
  it('filters variables that do not contain a key', () => {
    const expectedVariables = [
      {
        key: 'var_without_value',
        value: '',
        variableType: 'ENV_VAR',
      },
      {
        key: 'var_with_value',
        value: 'test_value',
        variableType: 'ENV_VAR',
      },
    ];

    expect(filterVariables(mockVariables)).toEqual(expectedVariables);
  });
});
