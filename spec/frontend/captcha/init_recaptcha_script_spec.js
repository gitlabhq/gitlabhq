import {
  RECAPTCHA_API_URL_PREFIX,
  RECAPTCHA_ONLOAD_CALLBACK_NAME,
  clearMemoizeCache,
  initRecaptchaScript,
} from '~/captcha/init_recaptcha_script';

describe('initRecaptchaScript', () => {
  afterEach(() => {
    // NOTE: The DOM is guaranteed to be clean at the start of a new test file, but it isn't cleaned
    // between examples within a file, so we need to clean it after each one.  See more context here:
    // - https://github.com/facebook/jest/issues/1224
    // - https://stackoverflow.com/questions/42805128/does-jest-reset-the-jsdom-document-after-every-suite-or-test
    //
    // Also note as mentioned in https://github.com/facebook/jest/issues/1224#issuecomment-444586798
    // that properties of `window` are NOT cleared between test files. So, we are also
    // explicitly unsetting it.
    document.head.innerHTML = '';
    window[RECAPTCHA_ONLOAD_CALLBACK_NAME] = undefined;
    clearMemoizeCache();
  });

  const triggerScriptOnload = (...args) => window[RECAPTCHA_ONLOAD_CALLBACK_NAME](...args);

  describe('when called', () => {
    let result;

    beforeEach(() => {
      result = initRecaptchaScript();
    });

    it('adds script to head', () => {
      expect(document.head).toMatchInlineSnapshot(`
        <head>
          <script
            class="js-recaptcha-script"
            src="${RECAPTCHA_API_URL_PREFIX}?onload=${RECAPTCHA_ONLOAD_CALLBACK_NAME}&render=explicit"
          />
        </head>
      `);
    });

    it('is memoized', () => {
      expect(initRecaptchaScript()).toBe(result);
      expect(document.head.querySelectorAll('script').length).toBe(1);
    });

    it('when onload is triggered, resolves promise', async () => {
      const instance = {};

      triggerScriptOnload(instance);

      await expect(result).resolves.toBe(instance);
    });
  });
});
