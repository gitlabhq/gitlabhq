const axios = jest.requireActual('~/lib/utils/axios_utils').default;

axios.isMock = true;

// Fail tests for unmocked requests
axios.defaults.adapter = config => {
  const message =
    `Unexpected unmocked request: ${JSON.stringify(config, null, 2)}\n` +
    'Consider using the `axios-mock-adapter` module in tests.';
  const error = new Error(message);
  error.config = config;
  global.fail(error);
  throw error;
};

export default axios;
