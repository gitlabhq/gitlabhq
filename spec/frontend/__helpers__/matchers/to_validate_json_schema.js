// NOTE: Make sure to initialize ajv when using this helper

const getAjvErrorMessage = ({ errors }) => {
  return (errors || []).map((error) => {
    return `Error with item ${error.instancePath}: ${error.message}`;
  });
};

export function toValidateJsonSchema(testData, validator) {
  if (!(validator instanceof Function && validator.schema)) {
    return {
      validator,
      message: () =>
        'Validator must be a validating function with property "schema", created with `ajv.compile`. See https://ajv.js.org/api.html#ajv-compile-schema-object-data-any-boolean-promise-any.',
      pass: false,
    };
  }

  const isValid = validator(testData);

  return {
    actual: testData,
    message: () => {
      if (isValid) {
        // We can match, but still fail because we're in a `expect...not.` context
        return 'Expected the given data not to pass the schema validation, but found that it was considered valid.';
      }

      const errorMessages = getAjvErrorMessage(validator).join('\n');
      return `Expected the given data to pass the schema validation, but found that it was considered invalid. Errors:\n${errorMessages}`;
    },
    pass: isValid,
  };
}
