import MockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import { ACCESS_LEVELS } from '~/protected_branches/constants';
import axios from '~/lib/utils/axios_utils';

const FORCE_PUSH_TOGGLE_TESTID = 'force-push-toggle';
const CODE_OWNER_TOGGLE_TESTID = 'code-owner-toggle';
const IS_CHECKED_CLASS = 'is-checked';
const IS_DISABLED_CLASS = 'is-disabled';
const IS_LOADING_CLASS = 'toggle-loading';

describe('ProtectedBranchCreate', () => {
  beforeEach(() => {
    // eslint-disable-next-line no-unused-vars
    const mock = new MockAdapter(axios);
    window.gon = {
      merge_access_levels: { roles: [] },
      push_access_levels: { roles: [] },
      abilities: { adminProject: true },
    };
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
    setHTMLFixture(`
      <form class="js-new-protected-branch">
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
        <div class="merge_access_levels-container">
            <div class="js-allowed-to-merge"/>
        </div>
        <div class="push_access_levels-container">
            <div class="js-allowed-to-push"/>
        </div>
        <input type="submit" />
      </form>
    `);

    return new ProtectedBranchCreate({ hasLicense });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when license supports code owner approvals', () => {
    it('instantiates the code owner toggle', () => {
      create();

      expect(findCodeOwnerToggle()).not.toBe(null);
    });
  });

  describe('when license does not support code owner approvals', () => {
    it('does not instantiate the code owner toggle', () => {
      create({ hasLicense: false });

      expect(findCodeOwnerToggle()).toBe(null);
    });
  });

  describe.each`
    description     | checkedOption               | finder
    ${'force push'} | ${'forcePushToggleChecked'} | ${findForcePushToggle}
    ${'code owner'} | ${'codeOwnerToggleChecked'} | ${findCodeOwnerToggle}
  `('when unchecked $description toggle button', ({ checkedOption, finder }) => {
    it('is not changed', () => {
      create({ [checkedOption]: false });

      const toggle = finder();

      expect(toggle).not.toHaveClass(IS_CHECKED_CLASS);
      expect(toggle.querySelector(`.${IS_LOADING_CLASS}`)).toBe(null);
      expect(toggle).not.toHaveClass(IS_DISABLED_CLASS);
    });
  });

  describe('form data', () => {
    let protectedBranchCreate;

    beforeEach(() => {
      protectedBranchCreate = create({
        forcePushToggleChecked: false,
        codeOwnerToggleChecked: true,
      });
    });

    afterEach(() => {
      protectedBranchCreate = null;
    });

    it('returns the default form data if toggles are untouched', () => {
      expect(protectedBranchCreate.getFormData().protected_branch).toMatchObject({
        allow_force_push: false,
        code_owner_approval_required: true,
      });
    });

    it('reflects toggles changes if any', () => {
      findForcePushToggle().click();
      findCodeOwnerToggle().click();

      expect(protectedBranchCreate.getFormData().protected_branch).toMatchObject({
        allow_force_push: true,
        code_owner_approval_required: false,
      });
    });
  });

  describe('access dropdown', () => {
    let protectedBranchCreate;

    beforeEach(() => {
      protectedBranchCreate = create();
    });

    it('should be initialized', () => {
      expect(protectedBranchCreate[`${ACCESS_LEVELS.MERGE}_dropdown`]).toBeDefined();
      expect(protectedBranchCreate[`${ACCESS_LEVELS.PUSH}_dropdown`]).toBeDefined();
    });

    describe('`select` event is emitted', () => {
      const selected = ['foo', 'bar'];

      it('should update selected merged access items', () => {
        protectedBranchCreate[`${ACCESS_LEVELS.MERGE}_dropdown`].$emit('select', selected);
        expect(protectedBranchCreate.selectedItems[ACCESS_LEVELS.MERGE]).toEqual(selected);
      });

      it('should update selected push access items', () => {
        protectedBranchCreate[`${ACCESS_LEVELS.PUSH}_dropdown`].$emit('select', selected);
        expect(protectedBranchCreate.selectedItems[ACCESS_LEVELS.PUSH]).toEqual(selected);
      });
    });
  });
});
