const NS_PER_SEC = 1e9;
const NS_PER_MS = 1e6;
const IS_DEBUGGING = process.execArgv.join(' ').includes('--inspect-brk');

let testTimeoutNS;

export const setTestTimeout = (newTimeoutMS) => {
  const newTimeoutNS = newTimeoutMS * NS_PER_MS;
  // never accept a smaller timeout than the default
  if (newTimeoutNS < testTimeoutNS) {
    return;
  }

  testTimeoutNS = newTimeoutNS;
  jest.setTimeout(newTimeoutMS);
};

// Allows slow tests to set their own timeout.
// Useful for tests with jQuery, which is very slow in big DOMs.
let temporaryTimeoutNS = null;
export const setTestTimeoutOnce = (newTimeoutMS) => {
  const newTimeoutNS = newTimeoutMS * NS_PER_MS;
  // never accept a smaller timeout than the default
  if (newTimeoutNS < testTimeoutNS) {
    return;
  }

  temporaryTimeoutNS = newTimeoutNS;
};

export const initializeTestTimeout = (defaultTimeoutMS) => {
  setTestTimeout(defaultTimeoutMS);

  let testStartTime;

  // https://github.com/facebook/jest/issues/6947
  beforeEach(() => {
    testStartTime = process.hrtime();
  });

  afterEach(() => {
    let timeoutNS = testTimeoutNS;
    if (Number.isFinite(temporaryTimeoutNS)) {
      timeoutNS = temporaryTimeoutNS;
      temporaryTimeoutNS = null;
    }

    const [seconds, remainingNs] = process.hrtime(testStartTime);
    const elapsedNS = seconds * NS_PER_SEC + remainingNs;

    // Disable the timeout error when debugging. It is meaningless because
    // debugging always takes longer than the test timeout.
    if (elapsedNS > timeoutNS && !IS_DEBUGGING) {
      throw new Error(
        `Test took too long (${elapsedNS / NS_PER_MS}ms > ${timeoutNS / NS_PER_MS}ms)!`,
      );
    }
  });
};
