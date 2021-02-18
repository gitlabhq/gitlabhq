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
  const triggerScriptOnload = () => window[RECAPTCHA_ONLOAD_CALLBACK_NAME]();

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

    describe('when onload is triggered', () => {
      beforeEach(() => {
        window.grecaptcha = 'fake grecaptcha';
        triggerScriptOnload();
      });

      afterEach(() => {
        window.grecaptcha = undefined;
      });

      it('resolves promise with window.grecaptcha as argument', async () => {
        await expect(result).resolves.toBe(window.grecaptcha);
      });

      it('sets window[RECAPTCHA_ONLOAD_CALLBACK_NAME] to undefined', async () => {
        expect(getScriptOnload()).toBeUndefined();
      });
    });
  });
});
