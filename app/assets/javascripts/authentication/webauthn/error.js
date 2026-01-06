import { __ } from '~/locale';
import { WEBAUTHN_AUTHENTICATE, WEBAUTHN_REGISTER } from './constants';
import { isSecureContext } from './util';

export default class WebAuthnError {
  constructor(error, flowType) {
    this.error = error;
    this.errorName = error.name || 'UnknownError';
    this.message = this.message.bind(this);
    this.httpsDisabled = !isSecureContext();
    this.flowType = flowType;
  }

  message() {
    // Browser side errors due to calling navigator.credentials.create
    if (this.errorName === 'NotSupportedError') {
      return __('Your device is not compatible with GitLab. Please try another device');
    }
    if (this.errorName === 'InvalidStateError' && this.flowType === WEBAUTHN_AUTHENTICATE) {
      return __('This device has not been registered with us.');
    }
    if (this.errorName === 'InvalidStateError' && this.flowType === WEBAUTHN_REGISTER) {
      return __('This device has already been registered with us.');
    }
    if (this.errorName === 'SecurityError' && this.httpsDisabled) {
      return __(
        'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.',
      );
    }

    return __('Failed to connect to your device. Try again.');
  }
}
