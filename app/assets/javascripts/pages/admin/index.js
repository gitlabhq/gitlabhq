import initAdmin from './admin';
import initUserInternalRegexPlaceholder from './application_settings/account_and_limits';

document.addEventListener('DOMContentLoaded', () => {
  initAdmin();
  initUserInternalRegexPlaceholder();
});
