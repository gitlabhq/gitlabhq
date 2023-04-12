import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ProtectedBranchEdit from '~/protected_branches/protected_branch_edit';

jest.mock('~/alert');

const TEST_URL = `${TEST_HOST}/url`;
const FORCE_PUSH_TOGGLE_TESTID = 'force-push-toggle';
const CODE_OWNER_TOGGLE_TESTID = 'code-owner-toggle';
const IS_CHECKED_CLASS = 'is-checked';
const IS_DISABLED_CLASS = 'is-disabled';
const IS_LOADING_SELECTOR = '.toggle-loading';

describe('ProtectedBranchEdit', () => {
  let mock;

  beforeEach(() => {
    jest.spyOn(ProtectedBranchEdit.prototype, 'buildDropdowns').mockImplementation();

    mock = new MockAdapter(axios);
  });

  const findForcePushToggle = () =>
    document.querySelector(`div[data-testid="${FORCE_PUSH_TOGGLE_TESTID}"] button`);
  const findCodeOwnerToggle = () =>
    document.querySelector(`div[data-testid="${CODE_OWNER_TOGGLE_TESTID}"] button`);

  const create = ({
    forcePushToggleChecked = false,
    codeOwnerToggleChecked = false,
    hasLicense = true,
  } = {}) => {
    setHTMLFixture(`<div id="wrap" data-url="${TEST_URL}">
      <span
        class="js-force-push-toggle"
        data-label="Toggle allowed to force push"
        data-is-checked="${forcePushToggleChecked}"
        data-testid="${FORCE_PUSH_TOGGLE_TESTID}"></span>
      <span
        class="js-code-owner-toggle"
        data-label="Toggle code owner approval"
        data-is-checked="${codeOwnerToggleChecked}"
        data-testid="${CODE_OWNER_TOGGLE_TESTID}"></span>
    </div>`);

    return new ProtectedBranchEdit({ $wrap: $('#wrap'), hasLicense });
  };

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  describe('when license supports code owner approvals', () => {
    beforeEach(() => {
      create();
    });

    it('instantiates the code owner toggle', () => {
      expect(findCodeOwnerToggle()).not.toBe(null);
    });
  });

  describe('when license does not support code owner approvals', () => {
    beforeEach(() => {
      create({ hasLicense: false });
    });

    it('does not instantiate the code owner toggle', () => {
      expect(findCodeOwnerToggle()).toBe(null);
    });
  });

  describe('when toggles are not available in the DOM on page load', () => {
    beforeEach(() => {
      create({ hasLicense: true });
      setHTMLFixture('');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('does not instantiate the force push toggle', () => {
      expect(findForcePushToggle()).toBe(null);
    });

    it('does not instantiate the code owner toggle', () => {
      expect(findCodeOwnerToggle()).toBe(null);
    });
  });

  describe.each`
    description     | checkedOption               | patchParam                        | finder
    ${'force push'} | ${'forcePushToggleChecked'} | ${'allow_force_push'}             | ${findForcePushToggle}
    ${'code owner'} | ${'codeOwnerToggleChecked'} | ${'code_owner_approval_required'} | ${findCodeOwnerToggle}
  `('when unchecked $description toggle button', ({ checkedOption, patchParam, finder }) => {
    let toggle;

    beforeEach(() => {
      create({ [checkedOption]: false });

      toggle = finder();
    });

    it('is not changed', () => {
      expect(toggle).not.toHaveClass(IS_CHECKED_CLASS);
      expect(toggle.querySelector(IS_LOADING_SELECTOR)).toBe(null);
      expect(toggle).not.toHaveClass(IS_DISABLED_CLASS);
    });

    describe('when clicked', () => {
      beforeEach(() => {
        mock
          .onPatch(TEST_URL, { protected_branch: { [patchParam]: true } })
          .replyOnce(HTTP_STATUS_OK, {});
      });

      it('checks and disables button', async () => {
        await toggle.click();

        expect(toggle).toHaveClass(IS_CHECKED_CLASS);
        expect(toggle.querySelector(IS_LOADING_SELECTOR)).not.toBe(null);
        expect(toggle).toHaveClass(IS_DISABLED_CLASS);
      });

      it('sends update to BE', async () => {
        await toggle.click();

        await axios.waitForAll();

        // Args are asserted in the `.onPatch` call
        expect(mock.history.patch).toHaveLength(1);

        expect(toggle).not.toHaveClass(IS_DISABLED_CLASS);
        expect(toggle.querySelector(IS_LOADING_SELECTOR)).toBe(null);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when clicked and BE error', () => {
      beforeEach(() => {
        mock.onPatch(TEST_URL).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        toggle.click();
      });

      it('alerts error', async () => {
        await axios.waitForAll();

        expect(createAlert).toHaveBeenCalled();
      });
    });
  });
});
