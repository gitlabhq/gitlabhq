import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import initNetworkOutbound from '~/admin/application_settings/network_outbound';

describe('initNetworkOutbound', () => {
  const findAllowCheckboxes = () => document.querySelectorAll('.js-allow-local-requests');
  const findDenyCheckbox = () => document.querySelector('.js-deny-all-requests');
  const findWarningBanner = () => document.querySelector('.js-deny-all-requests-warning');
  const clickDenyCheckbox = () => {
    findDenyCheckbox().click();
  };

  const createFixture = (denyAll = false) => {
    setHTMLFixture(`
      <input class="js-deny-all-requests" type="checkbox" name="application_setting[deny_all_requests_except_allowed]" ${
        denyAll ? 'checked="checked"' : ''
      }/>
      <div class="js-deny-all-requests-warning ${denyAll ? '' : 'gl-hidden'}"></div>
      <input class="js-allow-local-requests" type="checkbox" name="application_setting[allow_local_requests_from_web_hooks_and_services]" />
      <input class="js-allow-local-requests" type="checkbox" name="application_setting[allow_local_requests_from_system_hooks]" />
    `);
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when the checkbox is not checked', () => {
    beforeEach(() => {
      createFixture();
      initNetworkOutbound();
    });

    it('shows banner and disables allow checkboxes on change', () => {
      expect(findDenyCheckbox().checked).toBe(false);
      expect(findWarningBanner().classList).toContain('gl-hidden');

      clickDenyCheckbox();

      expect(findDenyCheckbox().checked).toBe(true);
      expect(findWarningBanner().classList).not.toContain('gl-hidden');
      const allowCheckboxes = findAllowCheckboxes();
      allowCheckboxes.forEach((checkbox) => {
        expect(checkbox.checked).toBe(false);
        expect(checkbox.disabled).toBe(true);
      });
    });
  });

  describe('when the checkbox is checked', () => {
    beforeEach(() => {
      createFixture(true);
      initNetworkOutbound();
    });

    it('hides banner and enables allow checkboxes on change', () => {
      expect(findDenyCheckbox().checked).toBe(true);
      expect(findWarningBanner().classList).not.toContain('gl-hidden');

      clickDenyCheckbox();

      expect(findDenyCheckbox().checked).toBe(false);
      expect(findWarningBanner().classList).toContain('gl-hidden');
      const allowCheckboxes = findAllowCheckboxes();
      allowCheckboxes.forEach((checkbox) => {
        expect(checkbox.disabled).toBe(false);
      });
    });
  });
});
