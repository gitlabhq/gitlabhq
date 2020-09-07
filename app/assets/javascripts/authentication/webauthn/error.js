import { __ } from '~/locale';
import { isHTTPS, FLOW_AUTHENTICATE, FLOW_REGISTER } from './util';

export default class WebAuthnError {
  constructor(error, flowType) {
    this.error = error;
    this.errorName = error.name || 'UnknownError';
    this.message = this.message.bind(this);
    this.httpsDisabled = !isHTTPS();
    this.flowType = flowType;
  }

  message() {
    if (this.errorName === 'NotSupportedError') {
      return __('Your device is not compatible with GitLab. Please try another device');
    } else if (this.errorName === 'InvalidStateError' && this.flowType === FLOW_AUTHENTICATE) {
      return __('This device has not been registered with us.');
    } else if (this.errorName === 'InvalidStateError' && this.flowType === FLOW_REGISTER) {
      return __('This device has already been registered with us.');
    } else if (this.errorName === 'SecurityError' && this.httpsDisabled) {
      return __(
        'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.',
      );
    }

    return __('There was a problem communicating with your device.');
  }
}
