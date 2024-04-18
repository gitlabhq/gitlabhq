import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ProtectedBranchEdit from '~/protected_branches/protected_branch_edit';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');

const TEST_URL = `${TEST_HOST}/url`;

const response = {
  project_id: 2,
  name: 'release/*',
  id: 30,
  created_at: '2023-09-21T03:06:27.532Z',
  updated_at: '2023-10-31T21:37:50.126Z',
  code_owner_approval_required: false,
  allow_force_push: false,
  namespace_id: null,
  merge_access_levels: [
    {
      id: 37,
      protected_branch_id: 30,
      access_level: 40,
      created_at: '2023-10-31T22:44:15.545Z',
      updated_at: '2023-10-31T22:44:15.545Z',
      user_id: null,
      group_id: null,
    },
  ],
  push_access_levels: [
    {
      id: 38,
      protected_branch_id: 30,
      access_level: 40,
      created_at: '2023-10-31T22:43:53.105Z',
      updated_at: '2023-10-31T22:43:53.105Z',
      user_id: null,
      group_id: null,
      deploy_key_id: null,
    },
    {
      id: 39,
      access_level: 40,
      deploy_key_id: 45,
    },
  ],
};

// Toggles
const FORCE_PUSH_TOGGLE_TESTID = 'force-push-toggle';
const CODE_OWNER_TOGGLE_TESTID = 'code-owner-toggle';
const IS_CHECKED_CLASS = 'is-checked';
const IS_DISABLED_CLASS = 'is-disabled';
const IS_LOADING_SELECTOR = '.toggle-loading';

// Dropdowns
const MERGE_DROPDOWN_TESTID = 'protected-branch-allowed-to-merge';
const PUSH_DROPDOWN_TESTID = 'protected-branch-allowed-to-push';
const INIT_MERGE_DATA_TESTID = 'js-allowed-to-merge';
const INIT_PUSH_DATA_TESTID = 'js-allowed-to-push';

describe('ProtectedBranchEdit', () => {
  let mock;

  const findForcePushToggle = () =>
    document.querySelector(`div[data-testid="${FORCE_PUSH_TOGGLE_TESTID}"] button`);
  const findCodeOwnerToggle = () =>
    document.querySelector(`div[data-testid="${CODE_OWNER_TOGGLE_TESTID}"] button`);
  const findMergeDropdown = () =>
    document.querySelector(`div[data-testid="${MERGE_DROPDOWN_TESTID}"]`);
  const findPushDropdown = () =>
    document.querySelector(`div[data-testid="${PUSH_DROPDOWN_TESTID}"]`);

  const create = ({
    forcePushToggleChecked = false,
    codeOwnerToggleChecked = false,
    mergeClass = INIT_MERGE_DATA_TESTID,
    mergeDisabled = false,
    mergePreselected = [],
    pushClass = INIT_PUSH_DATA_TESTID,
    pushDisabled = false,
    pushPreselected = [],
    hasLicense = true,
  } = {}) => {
    setHTMLFixture(`<div id="wrap" data-url="${TEST_URL}">
      <span
        class="${mergeClass}"
        data-label="Dropdown allowed to merge"
        data-disabled="${mergeDisabled}"
        data-preselected-items='${mergePreselected}'
        data-testid="${MERGE_DROPDOWN_TESTID}"></span>
      <span
        class="${pushClass}"
        data-label="Dropdown allowed to push"
        data-disabled="${pushDisabled}"
        data-preselected-items='${pushPreselected}'
        data-testid="${PUSH_DROPDOWN_TESTID}"></span>
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

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    resetHTMLFixture();
  });

  describe('dropdowns', () => {
    const accessLevels = [
      {
        id: 40,
        text: 'Maintainers',
        before_divider: true,
      },
      {
        id: 30,
        text: 'Developers + Maintainers',
        before_divider: true,
      },
    ];

    beforeEach(() => {
      window.gon = {
        current_project_id: 1,
        merge_access_levels: { roles: accessLevels },
        push_access_levels: { roles: accessLevels },
      };

      jest.spyOn(ProtectedBranchEdit.prototype, 'initToggles').mockImplementation();
    });

    describe('rendering', () => {
      describe('merge dropdown', () => {
        it('builds the merge dropdown when it has the proper class', () => {
          create();
          expect(findMergeDropdown()).not.toBe(null);
        });

        it('does not build the merge dropdown when it does not have the proper class', () => {
          create({ mergeClass: 'invalid-class' });
          expect(findMergeDropdown()).toBe(null);
        });
      });

      describe('push dropdown', () => {
        it('builds the push dropdown when it has the proper class', () => {
          create();
          expect(findPushDropdown()).not.toBe(null);
        });

        it('does not build the push dropdown when it does not have the proper class', () => {
          create({ pushClass: 'invalid-class' });
          expect(findPushDropdown()).toBe(null);
        });
      });
    });

    describe('preselected item', () => {
      beforeEach(() => {
        mock.onPatch(TEST_URL).reply(HTTP_STATUS_OK, response);
      });

      it('sets selected item on load', () => {
        const preselected = [{ id: 38, access_level: 40, type: 'role' }];
        const ProtectedBranchEditInstance = create({
          pushPreselected: JSON.stringify(preselected),
        });
        const dropdown = ProtectedBranchEditInstance.push_access_levels_dropdown;
        expect(dropdown.preselected).toEqual(preselected);
      });

      it('updates selected item on save for enabled dropdowns', async () => {
        const selectedValue = [{ access_level: 40 }];
        const ProtectedBranchEditInstance = create({});
        const dropdown = ProtectedBranchEditInstance.push_access_levels_dropdown;
        dropdown.$emit('select', selectedValue);
        dropdown.$emit('hidden');
        await waitForPromises();
        expect(dropdown.preselected[0].id).toBe(response.push_access_levels[0].id);
      });

      it('updates deploy key on save for enabled dropdowns', async () => {
        const selectedValue = [{ deploy_key_id: 45 }];
        const ProtectedBranchEditInstance = create({});
        const dropdown = ProtectedBranchEditInstance.push_access_levels_dropdown;
        dropdown.$emit('select', selectedValue);
        dropdown.$emit('hidden');
        await waitForPromises();
        expect(dropdown.preselected[1]).toEqual({
          deploy_key_id: 45,
          id: 39,
          persisted: true,
          type: 'deploy_key',
        });
      });

      it('does not update selected item on save for disabled dropdowns', async () => {
        const selectedValue = [{ access_level: 40 }];
        const ProtectedBranchEditInstance = create({ pushDisabled: '' });
        const dropdown = ProtectedBranchEditInstance.push_access_levels_dropdown;
        dropdown.$emit('select', selectedValue);
        dropdown.$emit('hidden');
        await waitForPromises();
        expect(dropdown.preselected).toEqual([]);
      });
    });

    describe('on hidden', () => {
      beforeEach(() => {
        mock.onPatch(TEST_URL).reply(HTTP_STATUS_OK, {});
      });

      it('does not update permissions on hidden if there are no changes', () => {
        const ProtectedBranchEditInstance = create();
        const dropdown = ProtectedBranchEditInstance.merge_access_levels_dropdown;
        dropdown.$emit('hidden');
        expect(mock.history.patch).toHaveLength(0);
      });

      it('updates permissions on hidden for enabled dropdowns with changes', async () => {
        const preselectedData = { id: 38, access_level: 40 };
        const preselected = [{ ...preselectedData, type: 'role' }];
        const selectedValue = [{ access_level: 30 }];
        const ProtectedBranchEditInstance = create({
          pushPreselected: JSON.stringify(preselected),
        });
        const dropdown = ProtectedBranchEditInstance.merge_access_levels_dropdown;
        dropdown.$emit('select', selectedValue);
        dropdown.$emit('hidden');
        await waitForPromises();
        expect(mock.history.patch).toHaveLength(1);
        expect(mock.history.patch[0].data).toEqual(
          JSON.stringify({
            protected_branch: {
              merge_access_levels_attributes: selectedValue,
              push_access_levels_attributes: [preselectedData],
            },
          }),
        );
      });

      it('does not update permissions on hidden for disabled dropdowns', async () => {
        const preselected = [{ id: 38, access_level: 0, type: 'role' }];
        const selectedValue = [{ access_level: 30 }];
        const ProtectedBranchEditInstance = create({
          mergeDisabled: '',
          mergePreselected: JSON.stringify(preselected),
        });
        const dropdown = ProtectedBranchEditInstance.push_access_levels_dropdown;
        dropdown.$emit('select', selectedValue);
        dropdown.$emit('hidden');
        await waitForPromises();
        expect(mock.history.patch).toHaveLength(1);
        expect(mock.history.patch[0].data).toEqual(
          JSON.stringify({
            protected_branch: {
              merge_access_levels_attributes: [],
              push_access_levels_attributes: selectedValue,
            },
          }),
        );
      });
    });
  });

  describe('toggles', () => {
    beforeEach(() => {
      jest.spyOn(ProtectedBranchEdit.prototype, 'initDropdowns').mockImplementation();
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
});
