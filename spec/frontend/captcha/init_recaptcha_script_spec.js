import {
  RECAPTCHA_API_URL_PREFIX,
  RECAPTCHA_ONLOAD_CALLBACK_NAME,
  clearMemoizeCache,
  initRecaptchaScript,
} from '~/captcha/init_recaptcha_script';

describe('initRecaptchaScript', () => {
  afterEach(() => {
    document.head.innerHTML = '';
    clearMemoizeCache();
  });

  const getScriptOnload = () => window[RECAPTCHA_ONLOAD_CALLBACK_NAME];
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
      expect(getScriptOnload()).toBeUndefined();
    });
  });
});
