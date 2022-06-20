import { nextTick } from 'vue';
import { getParameterByName } from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RuleEdit from '~/projects/settings/branch_rules/components/rule_edit.vue';
import BranchDropdown from '~/projects/settings/branch_rules/components/branch_dropdown.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterByName: jest.fn().mockImplementation(() => 'main'),
}));

describe('Edit branch rule', () => {
  let wrapper;
  const projectPath = 'test/testing';

  const createComponent = () => {
    wrapper = shallowMountExtended(RuleEdit, { propsData: { projectPath } });
  };

  const findBranchDropdown = () => wrapper.find(BranchDropdown);

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
});
