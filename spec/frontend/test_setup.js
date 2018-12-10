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
