const NS_PER_SEC = 1e9;
const NS_PER_MS = 1e6;

let testTimeoutNS;

export const setTestTimeout = newTimeoutMS => {
  testTimeoutNS = newTimeoutMS * NS_PER_MS;
  jest.setTimeout(newTimeoutMS);
};

export const initializeTestTimeout = defaultTimeoutMS => {
  setTestTimeout(defaultTimeoutMS);

  let testStartTime;

  // https://github.com/facebook/jest/issues/6947
  beforeEach(() => {
    testStartTime = process.hrtime();
  });

  afterEach(() => {
    const [seconds, remainingNs] = process.hrtime(testStartTime);
    const elapsedNS = seconds * NS_PER_SEC + remainingNs;

    if (elapsedNS > testTimeoutNS) {
      throw new Error(
        `Test took too long (${elapsedNS / NS_PER_MS}ms > ${testTimeoutNS / NS_PER_MS}ms)!`,
      );
    }
  });
};
