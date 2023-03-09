import { nextTick } from 'vue';
import { getParameterByName } from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RuleEdit from '~/projects/settings/branch_rules/components/edit/index.vue';
import BranchDropdown from '~/projects/settings/branch_rules/components/edit/branch_dropdown.vue';
import Protections from '~/projects/settings/branch_rules/components/edit/protections/index.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockImplementation(() => 'main'),
  joinPaths: jest.fn(),
  setUrlFragment: jest.fn(),
}));

describe('Edit branch rule', () => {
  let wrapper;
  const projectPath = 'test/testing';

  const createComponent = () => {
    wrapper = shallowMountExtended(RuleEdit, { propsData: { projectPath } });
  };

  const findBranchDropdown = () => wrapper.findComponent(BranchDropdown);
  const findProtections = () => wrapper.findComponent(Protections);

  beforeEach(() => createComponent());

  it('gets the branch param from url', () => {
    expect(getParameterByName).toHaveBeenCalledWith('branch');
  });

  describe('BranchDropdown', () => {
    it('renders a BranchDropdown component with the correct props', () => {
      expect(findBranchDropdown().props()).toMatchObject({
        projectPath,
        value: 'main',
      });
    });

    it('sets the correct value when `input` is emitted', async () => {
      const branch = 'test';
      findBranchDropdown().vm.$emit('input', branch);
      await nextTick();
      expect(findBranchDropdown().props('value')).toBe(branch);
    });

    it('sets the correct value when `createWildcard` is emitted', async () => {
      const wildcard = 'test-*';
      findBranchDropdown().vm.$emit('createWildcard', wildcard);
      await nextTick();
      expect(findBranchDropdown().props('value')).toBe(wildcard);
    });
  });

  describe('Protections', () => {
    it('renders a Protections component with the correct props', () => {
      expect(findProtections().props('protections')).toMatchObject({
        membersAllowedToPush: [],
        allowForcePush: false,
        membersAllowedToMerge: [],
        requireCodeOwnersApproval: false,
      });
    });

    it('updates protections when change-allowed-to-push-members is emitted', async () => {
      const membersAllowedToPush = ['test'];
      findProtections().vm.$emit('change-allowed-to-push-members', membersAllowedToPush);
      await nextTick();

      expect(findProtections().props('protections')).toEqual(
        expect.objectContaining({ membersAllowedToPush }),
      );
    });

    it('updates protections when change-allow-force-push is emitted', async () => {
      const allowForcePush = true;
      findProtections().vm.$emit('change-allow-force-push', allowForcePush);
      await nextTick();

      expect(findProtections().props('protections')).toEqual(
        expect.objectContaining({ allowForcePush }),
      );
    });

    it('updates protections when change-allowed-to-merge-members is emitted', async () => {
      const membersAllowedToMerge = ['test'];
      findProtections().vm.$emit('change-allowed-to-merge-members', membersAllowedToMerge);
      await nextTick();

      expect(findProtections().props('protections')).toEqual(
        expect.objectContaining({ membersAllowedToMerge }),
      );
    });

    it('updates protections when change-require-code-owners-approval is emitted', async () => {
      const requireCodeOwnersApproval = true;
      findProtections().vm.$emit('change-require-code-owners-approval', requireCodeOwnersApproval);
      await nextTick();

      expect(findProtections().props('protections')).toEqual(
        expect.objectContaining({ requireCodeOwnersApproval }),
      );
    });
  });
});
