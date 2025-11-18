/**
 * We need to filter out blank variables as well as variables that have no key
 * and then format the variables to GraphQL
 * before sending to the API to create a pipeline.
 */

export default (variables) => {
  return variables
    .filter(({ key, destroy }) => key !== '' && !destroy)
    .map(({ key, value, variableType }) => ({
      key,
      value,
      variableType,
    }));
};
