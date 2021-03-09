import MockAdapter from 'axios-mock-adapter';

import { registerCaptchaModalInterceptor } from '~/captcha/captcha_modal_axios_interceptor';
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
    mock = new MockAdapter(axios);
    mock.onAny('/no-captcha').reply(200, AXIOS_RESPONSE);
    mock.onAny('/error').reply(404, AXIOS_RESPONSE);
    mock.onAny('/captcha').reply((config) => {
      if (!supportedMethods.includes(config.method)) {
        return [httpStatusCodes.METHOD_NOT_ALLOWED, { method: config.method }];
      }

      try {
        const { captcha_response, spam_log_id, ...rest } = JSON.parse(config.data);
        // eslint-disable-next-line babel/camelcase
        if (captcha_response === CAPTCHA_RESPONSE && spam_log_id === SPAM_LOG_ID) {
          return [httpStatusCodes.OK, { ...rest, method: config.method, CAPTCHA_SUCCESS }];
        }
      } catch (e) {
        return [httpStatusCodes.BAD_REQUEST, { method: config.method }];
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
      const { data, status } = await axios[method]('/no-captcha');

      expect(status).toEqual(httpStatusCodes.OK);
      expect(data).toEqual(AXIOS_RESPONSE);
      expect(mock.history[method]).toHaveLength(1);
    });

    it('error requests without needs_captcha_response_errors are passed through', async () => {
      await expect(() => axios[method]('/error')).rejects.toThrow(
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

      it('re-submits request if captcha was solved correctly', async () => {
        waitForCaptchaToBeSolved.mockResolvedValue(CAPTCHA_RESPONSE);
        const { data: returnedData } = await axios[method]('/captcha', submittedData);

        expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);

        expect(returnedData).toEqual({ ...submittedData, CAPTCHA_SUCCESS, method });
        expect(mock.history[method]).toHaveLength(2);
      });

      it('does not re-submit request if captcha was not solved', async () => {
        const error = new Error('Captcha not solved');
        waitForCaptchaToBeSolved.mockRejectedValue(error);
        await expect(() => axios[method]('/captcha', submittedData)).rejects.toThrow(error);

        expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);
        expect(mock.history[method]).toHaveLength(1);
      });
    });
  });

  describe.each(unsupportedMethods)('For HTTP method %s', (method) => {
    it('ignores captcha response', async () => {
      await expect(() => axios[method]('/captcha')).rejects.toThrow(
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
