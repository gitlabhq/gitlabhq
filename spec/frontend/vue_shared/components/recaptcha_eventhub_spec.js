import { eventHub, callbackName } from '~/vue_shared/components/recaptcha_eventhub';

describe('reCAPTCHA event hub', () => {
  // the following test case currently crashes
  // see https://gitlab.com/gitlab-org/gitlab/issues/29192#note_217840035
  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('throws an error for overriding the callback', () => {
    expect(() => {
      window[callbackName] = 'something';
    }).toThrow();
  });

  it('triggering callback emits a submit event', () => {
    const eventHandler = jest.fn();
    eventHub.$once('submit', eventHandler);

    window[callbackName]();

    expect(eventHandler).toHaveBeenCalled();
  });
});
