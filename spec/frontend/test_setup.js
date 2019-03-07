import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import axios from '~/lib/utils/axios_utils';

const testTimeoutInMs = 300;
jest.setTimeout(testTimeoutInMs);

let testStartTime;

// https://github.com/facebook/jest/issues/6947
beforeEach(() => {
  testStartTime = Date.now();
});

afterEach(() => {
  const elapsedTimeInMs = Date.now() - testStartTime;
  if (elapsedTimeInMs > testTimeoutInMs) {
    throw new Error(`Test took too long (${elapsedTimeInMs}ms > ${testTimeoutInMs}ms)!`);
  }
});

// fail tests for unmocked requests
beforeEach(done => {
  axios.defaults.adapter = config => {
    const error = new Error(`Unexpected unmocked request: ${JSON.stringify(config, null, 2)}`);
    error.config = config;
    done.fail(error);
    return Promise.reject(error);
  };

  done();
});

Vue.use(Translate);
