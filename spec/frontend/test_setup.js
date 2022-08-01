/* Setup for unit test environment */
// eslint-disable-next-line no-restricted-syntax
import { setImmediate } from 'timers';
import 'helpers/shared_test_setup';
import { initializeTestTimeout } from 'helpers/timeout';

initializeTestTimeout(process.env.CI ? 6000 : 500);

afterEach(() =>
  // give Promises a bit more time so they fail the right test
  // eslint-disable-next-line no-restricted-syntax
  new Promise(setImmediate).then(() => {
    // wait for pending setTimeout()s
    jest.runOnlyPendingTimers();
  }),
);
