import $ from 'jquery';
import initUserInternalRegexPlaceholder, {
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE,
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE,
} from '~/pages/admin/application_settings/account_and_limits';

describe('AccountAndLimits', () => {
  const FIXTURE = 'application_settings/accounts_and_limit.html';
  let $userDefaultExternal;
  let $userInternalRegex;

  beforeEach(() => {
    loadFixtures(FIXTURE);
    initUserInternalRegexPlaceholder();
    $userDefaultExternal = $('#application_setting_user_default_external');
    $userInternalRegex = document.querySelector('#application_setting_user_default_internal_regex');
  });

  describe('Changing of userInternalRegex when userDefaultExternal', () => {
    it('is unchecked', () => {
      expect($userDefaultExternal.prop('checked')).toBeFalsy();
      expect($userInternalRegex.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE);
      expect($userInternalRegex.readOnly).toBeTruthy();
    });

    it('is checked', (done) => {
      if (!$userDefaultExternal.prop('checked')) $userDefaultExternal.click();

      expect($userDefaultExternal.prop('checked')).toBeTruthy();
      expect($userInternalRegex.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE);
      expect($userInternalRegex.readOnly).toBeFalsy();
      done();
    });
  });
});
