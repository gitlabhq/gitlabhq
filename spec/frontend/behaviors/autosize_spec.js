import '~/behaviors/autosize';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/helpers/startup_css_helper', () => {
  return {
    waitForCSSLoaded: jest.fn().mockImplementation((cb) => {
      // This is a hack:
      // autosize.js will execute and modify the DOM
      // whenever waitForCSSLoaded calls its callback function.
      // This setTimeout is here because everything within setTimeout will be queued
      // as async code until the current call stack is executed.
      // If we would not do this, the mock for waitForCSSLoaded would call its callback
      // before the fixture in the beforeEach is set and the Test would fail.
      // more on this here: https://johnresig.com/blog/how-javascript-timers-work/
      setTimeout(() => {
        cb.apply();
      }, 0);
    }),
  };
});

describe('Autosize behavior', () => {
  beforeEach(() => {
    setHTMLFixture('<textarea class="js-autosize"></textarea>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('is applied to the textarea', () => {
    // This is the second part of the Hack:
    // Because we are forcing the mock for WaitForCSSLoaded and the very end of our callstack
    // to call its callback. This querySelector needs to go to the very end of our callstack
    // as well, if we would not have this jest.runOnlyPendingTimers here, the querySelector
    // would not run and the test would fail.
    jest.runOnlyPendingTimers();

    const textarea = document.querySelector('textarea');
    expect(textarea.classList).toContain('js-autosize-initialized');
  });
});
