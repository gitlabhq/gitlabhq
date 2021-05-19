// We need to filter out blank variables
// and filter out variables that have no key
// before sending to the API to create a pipeline.

export default (variables) => {
  return variables
    .filter(({ key }) => key !== '')
    .map(({ variable_type, key, value }) => ({
      variable_type,
      key,
      secret_value: value,
    }));
};
