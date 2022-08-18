import $ from 'jquery';
import { loadHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initUserInternalRegexPlaceholder, {
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE,
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE,
} from '~/pages/admin/application_settings/account_and_limits';

describe('AccountAndLimits', () => {
  const FIXTURE = 'application_settings/accounts_and_limit.html';
  let $userDefaultExternal;
  let $userInternalRegex;

  beforeEach(() => {
    loadHTMLFixture(FIXTURE);
    initUserInternalRegexPlaceholder();
    $userDefaultExternal = $('#application_setting_user_default_external');
    $userInternalRegex = document.querySelector('#application_setting_user_default_internal_regex');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('Changing of userInternalRegex when userDefaultExternal', () => {
    it('is unchecked', () => {
      expect($userDefaultExternal.prop('checked')).toBe(false);
      expect($userInternalRegex.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE);
      expect($userInternalRegex.readOnly).toBe(true);
    });

    it('is checked', () => {
      if (!$userDefaultExternal.prop('checked')) $userDefaultExternal.click();

      expect($userDefaultExternal.prop('checked')).toBe(true);
      expect($userInternalRegex.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE);
      expect($userInternalRegex.readOnly).toBe(false);
    });
  });
});
