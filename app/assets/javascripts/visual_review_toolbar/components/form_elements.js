import { REMEMBER_ITEM } from '../shared';
import { buttonClearStyles } from './utils';

/* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
const rememberBox = (rememberText = 'Remember me') => `
  <div class="gitlab-checkbox-wrapper">
    <input type="checkbox" id="${REMEMBER_ITEM}" name="${REMEMBER_ITEM}" value="remember">
    <label for="${REMEMBER_ITEM}" class="gitlab-checkbox-label">${rememberText}</label>
  </div>
`;

const submitButton = buttonId => `
  <div class="gitlab-button-wrapper">
    <button class="gitlab-button-wide gitlab-button gitlab-button-success" style="${buttonClearStyles}" type="button" id="${buttonId}"> Submit </button>
  </div>
`;
export { rememberBox, submitButton };
