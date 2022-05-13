import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';

const FORCE_PUSH_TOGGLE_TESTID = 'force-push-toggle';
const CODE_OWNER_TOGGLE_TESTID = 'code-owner-toggle';
const IS_CHECKED_CLASS = 'is-checked';
const IS_DISABLED_CLASS = 'is-disabled';
const IS_LOADING_CLASS = 'toggle-loading';

describe('ProtectedBranchCreate', () => {
  beforeEach(() => {
    jest.spyOn(ProtectedBranchCreate.prototype, 'buildDropdowns').mockImplementation();
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

      // Mock access levels. This should probably be improved in future iterations.
      protectedBranchCreate.merge_access_levels_dropdown = {
        getSelectedItems: () => [],
      };
      protectedBranchCreate.push_access_levels_dropdown = {
        getSelectedItems: () => [],
      };
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
});
