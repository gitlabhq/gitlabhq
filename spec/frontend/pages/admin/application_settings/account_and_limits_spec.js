import htmlApplicationSettingsAccountsAndLimit from 'test_fixtures/application_settings/accounts_and_limit.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initAccountAndLimitsSection, {
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE,
  PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE,
} from '~/pages/admin/application_settings/account_and_limits';

describe('AccountAndLimits', () => {
  beforeEach(() => {
    setHTMLFixture(htmlApplicationSettingsAccountsAndLimit);
    initAccountAndLimitsSection();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('Changing of userInternalRegex when userDefaultExternal', () => {
    /** @type {HTMLInputElement} */
    let userDefaultExternalCheckbox;
    /** @type {HTMLInputElement} */
    let userInternalRegexInput;

    beforeEach(() => {
      userDefaultExternalCheckbox = document.getElementById(
        'application_setting_user_default_external',
      );
      userInternalRegexInput = document.getElementById(
        'application_setting_user_default_internal_regex',
      );
    });

    it('is unchecked', () => {
      expect(userDefaultExternalCheckbox.checked).toBe(false);
      expect(userInternalRegexInput.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_FALSE);
      expect(userInternalRegexInput.readOnly).toBe(true);
    });

    it('is checked', () => {
      if (!userDefaultExternalCheckbox.checked) userDefaultExternalCheckbox.click();

      expect(userDefaultExternalCheckbox.checked).toBe(true);
      expect(userInternalRegexInput.placeholder).toEqual(PLACEHOLDER_USER_EXTERNAL_DEFAULT_TRUE);
      expect(userInternalRegexInput.readOnly).toBe(false);
    });
  });

  describe('Dormant users period input logic', () => {
    /** @type {HTMLInputElement} */
    let checkbox;
    /** @type {HTMLInputElement} */
    let input;

    const updateCheckbox = (checked) => {
      checkbox.checked = checked;
      checkbox.dispatchEvent(new Event('change'));
    };

    beforeEach(() => {
      checkbox = document.getElementById('application_setting_deactivate_dormant_users');
      input = document.getElementById('application_setting_deactivate_dormant_users_period');
    });

    it('initial state', () => {
      expect(checkbox.checked).toBe(false);
      expect(input.disabled).toBe(true);
    });

    it('changes field enabled flag on checkbox change', () => {
      updateCheckbox(true);
      expect(input.disabled).toBe(false);

      updateCheckbox(false);
      expect(input.disabled).toBe(true);
    });
  });
});
