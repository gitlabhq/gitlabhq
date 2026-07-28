import { getByTestId, fireEvent } from '@testing-library/dom';
import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setWindowLocation from 'helpers/set_window_location_helper';
import {
  initRecoveryCodes,
  initClose2faSuccessMessage,
  initTwoFactorGraceDeadline,
} from '~/authentication/two_factor_auth';
import RecoveryCodes from '~/authentication/two_factor_auth/components/recovery_codes.vue';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import * as urlUtils from '~/lib/utils/url_utility';
import { codesJsonString, codes, redirectPath } from './mock_data';

describe('initRecoveryCodes', () => {
  let wrapper;

  const findRecoveryCodesComponent = () => wrapper.findComponent(RecoveryCodes);

  beforeEach(() => {
    setHTMLFixture(
      `<div class='js-2fa-recovery-codes' data-codes='${codesJsonString}' data-redirect-path='${redirectPath}'></div>`,
    );
    wrapper = createWrapper(initRecoveryCodes());
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('parses `data-codes` and passes to `RecoveryCodes` as `codes` prop', () => {
    expect(findRecoveryCodesComponent().props('codes')).toEqual(codes);
  });

  it('parses `data-profile-account-path` and passes to `RecoveryCodes` as `redirectPath` prop', () => {
    expect(findRecoveryCodesComponent().props('redirectPath')).toEqual(redirectPath);
  });
});

describe('initTwoFactorGraceDeadline', () => {
  const datetime = '2026-07-16T23:36:58Z';

  afterEach(() => {
    resetHTMLFixture();
  });

  it('replaces the fallback text with the browser-local formatted deadline', () => {
    setHTMLFixture(
      `<time class="js-local-datetime" datetime="${datetime}">July 16, 2026 23:36</time>`,
    );

    initTwoFactorGraceDeadline();

    expect(document.querySelector('.js-local-datetime').textContent).toBe(
      localeDateFormat.asDateTimeWithTimezone.format(newDate(datetime)),
    );
  });
});

describe('initClose2faSuccessMessage', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <button
        data-testid="close-2fa-enabled-success-alert"
        class="js-close-2fa-enabled-success-alert"
      >
      </button>
    `);

    initClose2faSuccessMessage();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when alert is closed', () => {
    beforeEach(() => {
      setWindowLocation(
        'https://localhost/-/profile/account?two_factor_auth_enabled_successfully=true',
      );

      document.title = 'foo bar';

      urlUtils.updateHistory = jest.fn();
    });

    afterEach(() => {
      document.title = '';
    });

    it('removes `two_factor_auth_enabled_successfully` query param', () => {
      fireEvent.click(getByTestId(document.body, 'close-2fa-enabled-success-alert'));

      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: 'https://localhost/-/profile/account',
        title: 'foo bar',
        replace: true,
      });
    });
  });
});
