import { __ } from '~/locale';

class UnsolvedCaptchaError extends Error {
  constructor(message) {
    super(message || __('You must solve the CAPTCHA in order to submit'));
    this.name = 'UnsolvedCaptchaError';
  }
}

export default UnsolvedCaptchaError;
