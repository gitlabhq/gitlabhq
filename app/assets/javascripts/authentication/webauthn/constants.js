import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const I18N_BUTTON_REGISTER = __('Register device');
export const I18N_BUTTON_SETUP = __('Set up new device');
export const I18N_BUTTON_TRY_AGAIN = __('Try again?');
export const I18N_DEVICE_NAME = __('Device name');
export const I18N_DEVICE_NAME_DESCRIPTION = __(
  'Excluding USB security keys, you should include the browser name together with the device name.',
);
export const I18N_DEVICE_NAME_PLACEHOLDER = __('Macbook Touch ID on Edge');
export const I18N_ERROR_HTTP = __(
  'WebAuthn only works with HTTPS-enabled websites. Contact your administrator for more details.',
);
export const I18N_ERROR_UNSUPPORTED_BROWSER = __(
  "Your browser doesn't support WebAuthn. Please use a supported browser, e.g. Chrome (67+) or Firefox (60+).",
);
export const I18N_NOTICE = __(
  'You must save your recovery codes after you first register a two-factor authenticator, so you do not lose access to your account. %{linkStart}See the documentation on managing your WebAuthn device for more information.%{linkEnd}',
);
export const I18N_PASSWORD = __('Current password');
export const I18N_PASSWORD_DESCRIPTION = __(
  'Your current password is required to register a new device.',
);
export const I18N_STATUS_SUCCESS = __(
  'Your device was successfully set up! Give it a name and register it with the GitLab server.',
);
export const I18N_STATUS_WAITING = __(
  'Trying to communicate with your device. Plug it in (if needed) and press the button on the device now.',
);

export const STATE_ERROR = 'error';
export const STATE_READY = 'ready';
export const STATE_SUCCESS = 'success';
export const STATE_UNSUPPORTED = 'unsupported';
export const STATE_WAITING = 'waiting';

export const WEBAUTHN_AUTHENTICATE = 'authenticate';
export const WEBAUTHN_REGISTER = 'register';
export const WEBAUTHN_DOCUMENTATION_PATH = helpPagePath(
  'user/profile/account/two_factor_authentication',
  { anchor: 'set-up-a-webauthn-device' },
);
