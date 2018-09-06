import 'jest-extended';

const testTimeoutInMs = 1000;
jest.setTimeout(testTimeoutInMs);

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
