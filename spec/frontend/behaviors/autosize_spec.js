import '~/behaviors/autosize';

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
    setFixtures('<textarea class="js-autosize"></textarea>');
  });

  it('is applied to the textarea', () => {
    // This is the second part of the Hack:
    // Because we are forcing the mock for WaitForCSSLoaded and the very end of our callstack
    // to call its callback. This querySelector needs to go to the very end of our callstack
    // as well, if we would not have this setTimeout Function here, the querySelector
    // would run before the mockImplementation called its callBack Function
    // the DOM Manipulation didn't happen yet and the test would fail.
    setTimeout(() => {
      const textarea = document.querySelector('textarea');
      expect(textarea.classList).toContain('js-autosize-initialized');
    }, 0);
  });
});
