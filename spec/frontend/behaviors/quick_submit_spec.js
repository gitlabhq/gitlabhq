import $ from 'jquery';
import '~/behaviors/quick_submit';

describe('Quick Submit behavior', () => {
  let testContext;

  const keydownEvent = (options = { keyCode: 13, metaKey: true }) => $.Event('keydown', options);

  beforeEach(() => {
    loadFixtures('snippets/show.html');

    testContext = {};

    testContext.spies = {
      submit: jest.fn(),
    };

    $('form').submit((e) => {
      // Prevent a form submit from moving us off the testing page
      e.preventDefault();
      // Explicitly call the spie to know this function get's not called
      testContext.spies.submit();
    });
    testContext.textarea = $('.js-quick-submit textarea').first();
  });

  it('does not respond to other keyCodes', () => {
    testContext.textarea.trigger(
      keydownEvent({
        keyCode: 32,
      }),
    );

    expect(testContext.spies.submit).not.toHaveBeenCalled();
  });

  it('does not respond to Enter alone', () => {
    testContext.textarea.trigger(
      keydownEvent({
        ctrlKey: false,
        metaKey: false,
      }),
    );

    expect(testContext.spies.submit).not.toHaveBeenCalled();
  });

  it('does not respond to repeated events', () => {
    testContext.textarea.trigger(
      keydownEvent({
        repeat: true,
      }),
    );

    expect(testContext.spies.submit).not.toHaveBeenCalled();
  });

  it('disables input of type submit', () => {
    const submitButton = $('.js-quick-submit input[type=submit]');
    testContext.textarea.trigger(keydownEvent());

    expect(submitButton).toBeDisabled();
  });

  it('disables button of type submit', () => {
    const submitButton = $('.js-quick-submit input[type=submit]');
    testContext.textarea.trigger(keydownEvent());

    expect(submitButton).toBeDisabled();
  });

  it('only clicks one submit', () => {
    const existingSubmit = $('.js-quick-submit input[type=submit]');
    // Add an extra submit button
    const newSubmit = $('<button type="submit">Submit it</button>');
    newSubmit.insertAfter(testContext.textarea);

    const spies = {
      oldClickSpy: jest.fn(),
      newClickSpy: jest.fn(),
    };
    existingSubmit.on('click', () => {
      spies.oldClickSpy();
    });
    newSubmit.on('click', () => {
      spies.newClickSpy();
    });

    testContext.textarea.trigger(keydownEvent());

    expect(spies.oldClickSpy).not.toHaveBeenCalled();
    expect(spies.newClickSpy).toHaveBeenCalled();
  });
  // We cannot stub `navigator.userAgent` for CI's `rake karma` task, so we'll
  // only run the tests that apply to the current platform
  if (navigator.userAgent.match(/Macintosh/)) {
    describe('In Macintosh', () => {
      it('responds to Meta+Enter', () => {
        testContext.textarea.trigger(keydownEvent());

        expect(testContext.spies.submit).toHaveBeenCalled();
      });

      it('excludes other modifier keys', () => {
        testContext.textarea.trigger(
          keydownEvent({
            altKey: true,
          }),
        );
        testContext.textarea.trigger(
          keydownEvent({
            ctrlKey: true,
          }),
        );
        testContext.textarea.trigger(
          keydownEvent({
            shiftKey: true,
          }),
        );

        expect(testContext.spies.submit).not.toHaveBeenCalled();
      });
    });
  } else {
    it('responds to Ctrl+Enter', () => {
      testContext.textarea.trigger(keydownEvent());

      expect(testContext.spies.submit).toHaveBeenCalled();
    });

    it('excludes other modifier keys', () => {
      testContext.textarea.trigger(
        keydownEvent({
          altKey: true,
        }),
      );
      testContext.textarea.trigger(
        keydownEvent({
          metaKey: true,
        }),
      );
      testContext.textarea.trigger(
        keydownEvent({
          shiftKey: true,
        }),
      );

      expect(testContext.spies.submit).not.toHaveBeenCalled();
    });
  }
});
