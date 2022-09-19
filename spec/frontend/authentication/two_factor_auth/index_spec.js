import { getByTestId, fireEvent } from '@testing-library/dom';
import { createWrapper } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { initRecoveryCodes, initClose2faSuccessMessage } from '~/authentication/two_factor_auth';
import RecoveryCodes from '~/authentication/two_factor_auth/components/recovery_codes.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import { codesJsonString, codes, profileAccountPath } from './mock_data';

describe('initRecoveryCodes', () => {
  let el;
  let wrapper;

  const findRecoveryCodesComponent = () => wrapper.findComponent(RecoveryCodes);

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('class', 'js-2fa-recovery-codes');
    el.dataset.codes = codesJsonString;
    el.dataset.profileAccountPath = profileAccountPath;
    document.body.appendChild(el);

    wrapper = createWrapper(initRecoveryCodes());
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('parses `data-codes` and passes to `RecoveryCodes` as `codes` prop', () => {
    expect(findRecoveryCodesComponent().props('codes')).toEqual(codes);
  });

  it('parses `data-profile-account-path` and passes to `RecoveryCodes` as `profileAccountPath` prop', () => {
    expect(findRecoveryCodesComponent().props('profileAccountPath')).toEqual(profileAccountPath);
  });
});

describe('initClose2faSuccessMessage', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <button
        data-testid="close-2fa-enabled-success-alert"
        class="js-close-2fa-enabled-success-alert"
      >
      </button>
    `;

    initClose2faSuccessMessage();
  });

  afterEach(() => {
    document.body.innerHTML = '';
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
