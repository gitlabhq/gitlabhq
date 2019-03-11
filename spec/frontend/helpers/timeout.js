let testTimeoutInMs;

export const setTestTimeout = newTimeoutInMs => {
  testTimeoutInMs = newTimeoutInMs;
  jest.setTimeout(newTimeoutInMs);
};

export const initializeTestTimeout = defaultTimeoutInMs => {
  setTestTimeout(defaultTimeoutInMs);

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
};
