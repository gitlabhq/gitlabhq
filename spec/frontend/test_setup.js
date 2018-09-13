import 'jest-extended';
import { initializeAxios } from './helpers/axios_mock';

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

process.on('unhandledRejection', (error) => {
  console.error('Unhandled Promise rejection:', error);
  process.exit(1);
});
