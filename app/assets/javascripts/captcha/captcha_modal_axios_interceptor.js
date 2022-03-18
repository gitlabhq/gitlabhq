const SUPPORTED_METHODS = ['patch', 'post', 'put'];

function needsCaptchaResponse(err) {
  return (
    SUPPORTED_METHODS.includes(err?.config?.method) && err?.response?.data?.needs_captcha_response
  );
}

const showCaptchaModalAndResubmit = async (axios, data, errConfig) => {
  // NOTE: We asynchronously import and unbox the module. Since this is included globally, we don't
  // do a regular import because that would increase the size of the webpack bundle.
  const { waitForCaptchaToBeSolved } = await import(
    'jh_else_ce/captcha/wait_for_captcha_to_be_solved'
  );

  // show the CAPTCHA modal and wait for it to be solved or closed
  const captchaResponse = await waitForCaptchaToBeSolved(data.captcha_site_key);

  // resubmit the original request with the captcha_response and spam_log_id in the headers
  const originalData = JSON.parse(errConfig.data);
  const originalHeaders = errConfig.headers;
  return axios({
    method: errConfig.method,
    url: errConfig.url,
    headers: {
      ...originalHeaders,
      'X-GitLab-Captcha-Response': captchaResponse,
      'X-GitLab-Spam-Log-Id': data.spam_log_id,
    },
    data: originalData,
  });
};

export function registerCaptchaModalInterceptor(axios) {
  return axios.interceptors.response.use(
    (response) => {
      return response;
    },
    (err) => {
      if (needsCaptchaResponse(err)) {
        return showCaptchaModalAndResubmit(axios, err.response.data, err.config);
      }

      return Promise.reject(err);
    },
  );
}
