import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import axios from '~/lib/utils/axios_utils';
import { initializeTestTimeout } from './helpers/timeout';

process.on('unhandledRejection', global.promiseRejectionHandler);

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runAllTimers();
  }),
);

initializeTestTimeout(300);

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
