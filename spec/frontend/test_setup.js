import 'jest-extended';
import Translate from '~/vue_shared/translate';
import Vue from 'vue';
import { initializeAxios } from './helpers/axios_mock';

Vue.use(Translate);

const testTimeoutInMs = 1000;
jest.setTimeout(testTimeoutInMs);
jest.useFakeTimers();

let testStartTime;

// https://github.com/facebook/jest/issues/6947
beforeEach(() => {
  testStartTime = new Date().getTime();
});

afterEach(() => {
  if (new Date().getTime() - testStartTime > testTimeoutInMs) {
    throw new Error(`Test took longer than ${testTimeoutInMs}ms!`);
  }
});

afterEach(() => {
  jest.runAllTimers();
});

initializeAxios(beforeEach, afterEach);

process.on('unhandledRejection', error => {
  console.error('Unhandled Promise rejection:', error); // eslint-disable-line no-console
  process.exit(1);
});

beforeEach(done => {
  // https://github.com/vuejs/vue-test-utils/issues/631#issuecomment-421108344
  Vue.config.warnHandler = (msg, vm, trace) => {
    const currentStack = new Error('').stack;
    const isInVueTestUtils = currentStack.split('\n').some(line => line.startsWith('    at VueWrapper.setProps ('));
    if (isInVueTestUtils) {
      return;
    }
    done.fail(`${msg}${trace}`);
  };

  Vue.config.errorHandler = error => done.fail(error);

  done();
});
