import { createJestExecutionWatcher } from '../jest_execution_watcher';
import { RealDate, createFakeDateClass } from './fake_date';

const throwInsideExecutionError = (fnName) => {
  throw new Error(`Cannot call "${fnName}" during test execution (i.e. within "it", "beforeEach", "beforeAll", etc.).

Instead, please move the call to "${fnName}" inside the "describe" block itself.

      describe('', () => {
    +   ${fnName}();

        it('', () => {
    -     ${fnName}();
        })
      })
`);
};

const isExecutingTest = createJestExecutionWatcher();

export const useDateInScope = (fnName, factory) => {
  if (isExecutingTest()) {
    throwInsideExecutionError(fnName);
  }

  let origDate;

  beforeAll(() => {
    origDate = global.Date;
    global.Date = factory();
  });

  afterAll(() => {
    global.Date = origDate;
  });
};

export const useFakeDate = (...args) =>
  useDateInScope('useFakeDate', () => createFakeDateClass(args));

export const useRealDate = () => useDateInScope('useRealDate', () => RealDate);
