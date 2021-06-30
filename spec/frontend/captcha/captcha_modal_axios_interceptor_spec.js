import MockAdapter from 'axios-mock-adapter';

import { registerCaptchaModalInterceptor } from '~/captcha/captcha_modal_axios_interceptor';
import UnsolvedCaptchaError from '~/captcha/unsolved_captcha_error';
import { waitForCaptchaToBeSolved } from '~/captcha/wait_for_captcha_to_be_solved';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

jest.mock('~/captcha/wait_for_captcha_to_be_solved');

describe('registerCaptchaModalInterceptor', () => {
  const SPAM_LOG_ID = 'SPAM_LOG_ID';
  const CAPTCHA_SITE_KEY = 'CAPTCHA_SITE_KEY';
  const CAPTCHA_SUCCESS = 'CAPTCHA_SUCCESS';
  const CAPTCHA_RESPONSE = 'CAPTCHA_RESPONSE';
  const AXIOS_RESPONSE = { text: 'AXIOS_RESPONSE' };
  const NEEDS_CAPTCHA_RESPONSE = {
    needs_captcha_response: true,
    captcha_site_key: CAPTCHA_SITE_KEY,
    spam_log_id: SPAM_LOG_ID,
  };

  const unsupportedMethods = ['delete', 'get', 'head', 'options'];
  const supportedMethods = ['patch', 'post', 'put'];

  let mock;

  beforeEach(() => {
    waitForCaptchaToBeSolved.mockRejectedValue(new UnsolvedCaptchaError());

    mock = new MockAdapter(axios);
    mock.onAny('/endpoint-without-captcha').reply(200, AXIOS_RESPONSE);
    mock.onAny('/endpoint-with-unrelated-error').reply(404, AXIOS_RESPONSE);
    mock.onAny('/endpoint-with-captcha').reply((config) => {
      if (!supportedMethods.includes(config.method)) {
        return [httpStatusCodes.METHOD_NOT_ALLOWED, { method: config.method }];
      }

      const data = JSON.parse(config.data);
      const {
        'X-GitLab-Captcha-Response': captchaResponse,
        'X-GitLab-Spam-Log-Id': spamLogId,
      } = config.headers;

      if (captchaResponse === CAPTCHA_RESPONSE && spamLogId === SPAM_LOG_ID) {
        return [httpStatusCodes.OK, { ...data, method: config.method, CAPTCHA_SUCCESS }];
      }

      return [httpStatusCodes.CONFLICT, NEEDS_CAPTCHA_RESPONSE];
    });

    axios.interceptors.response.handlers = [];
    registerCaptchaModalInterceptor(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each([...supportedMethods, ...unsupportedMethods])('For HTTP method %s', (method) => {
    it('successful requests are passed through', async () => {
      const { data, status } = await axios[method]('/endpoint-without-captcha');

      expect(status).toEqual(httpStatusCodes.OK);
      expect(data).toEqual(AXIOS_RESPONSE);
      expect(mock.history[method]).toHaveLength(1);
    });

    it('error requests without needs_captcha_response_errors are passed through', async () => {
      await expect(() => axios[method]('/endpoint-with-unrelated-error')).rejects.toThrow(
        expect.objectContaining({
          response: expect.objectContaining({
            status: httpStatusCodes.NOT_FOUND,
            data: AXIOS_RESPONSE,
          }),
        }),
      );
      expect(mock.history[method]).toHaveLength(1);
    });
  });

  describe.each(supportedMethods)('For HTTP method %s', (method) => {
    describe('error requests with needs_captcha_response_errors', () => {
      const submittedData = { ID: 12345 };
      const submittedHeaders = { 'Submitted-Header': 67890 };

      it('re-submits request if captcha was solved correctly', async () => {
        waitForCaptchaToBeSolved.mockResolvedValueOnce(CAPTCHA_RESPONSE);
        const axiosResponse = await axios[method]('/endpoint-with-captcha', submittedData, {
          headers: submittedHeaders,
        });
        const {
          data: returnedData,
          config: { headers: returnedHeaders },
        } = axiosResponse;

        expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);

        expect(returnedData).toEqual({ ...submittedData, CAPTCHA_SUCCESS, method });
        expect(returnedHeaders).toEqual(
          expect.objectContaining({
            ...submittedHeaders,
            'X-GitLab-Captcha-Response': CAPTCHA_RESPONSE,
            'X-GitLab-Spam-Log-Id': SPAM_LOG_ID,
          }),
        );
        expect(mock.history[method]).toHaveLength(2);
      });

      it('does not re-submit request if captcha was not solved', async () => {
        await expect(() => axios[method]('/endpoint-with-captcha', submittedData)).rejects.toThrow(
          new UnsolvedCaptchaError(),
        );

        expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);
        expect(mock.history[method]).toHaveLength(1);
      });
    });
  });

  describe.each(unsupportedMethods)('For HTTP method %s', (method) => {
    it('ignores captcha response', async () => {
      await expect(() => axios[method]('/endpoint-with-captcha')).rejects.toThrow(
        expect.objectContaining({
          response: expect.objectContaining({
            status: httpStatusCodes.METHOD_NOT_ALLOWED,
            data: { method },
          }),
        }),
      );

      expect(waitForCaptchaToBeSolved).not.toHaveBeenCalled();
      expect(mock.history[method]).toHaveLength(1);
    });
  });
});
