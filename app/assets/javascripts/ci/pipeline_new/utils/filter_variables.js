/**
 * We need to filter out blank variables as well as variables that have no key
 * and then format the variables to GraphQL
 * before sending to the API to create a pipeline.
 */

export default (variables) => {
  return variables
    .filter(({ key }) => key !== '')
    .map(({ key, value, variable_type: variableType }) => ({
      key,
      value,
      // CiVariableType must be all caps
      variableType: variableType.toUpperCase(),
    }));
};
