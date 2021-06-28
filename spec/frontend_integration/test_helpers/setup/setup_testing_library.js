import { configure } from '@testing-library/dom';

const CUSTOM_ERROR_TYPE = 'TestingLibraryError';

configure({
  asyncUtilTimeout: 10000,
  // Overwrite default error message to reduce noise.
  getElementError: (messageArg) => {
    // Add to message because the `name` doesn't look like it's used (although it should).
    const message = `${CUSTOM_ERROR_TYPE}:\n\n${messageArg}`;
    const error = new Error(message);
    error.name = CUSTOM_ERROR_TYPE;
    return error;
  },
});
