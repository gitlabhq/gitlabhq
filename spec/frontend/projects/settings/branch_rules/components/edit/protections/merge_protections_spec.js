import { GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeProtections, {
  i18n,
} from '~/projects/settings/branch_rules/components/edit/protections/merge_protections.vue';
import { membersAllowedToMerge, requireCodeOwnersApproval } from '../../../mock_data';

describe('Merge Protections', () => {
  let wrapper;

  const propsData = {
    membersAllowedToMerge,
    requireCodeOwnersApproval,
  };

  const createComponent = () => {
    wrapper = mountExtended(MergeProtections, {
      propsData,
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findCodeOwnersApprovalCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  beforeEach(() => createComponent());

  it('renders a form group with the correct label', () => {
    expect(findFormGroup().text()).toContain(i18n.allowedToMerge);
  });

  describe('Require code owners approval checkbox', () => {
    it('renders a checkbox with the correct props', () => {
      expect(findCodeOwnersApprovalCheckbox().vm.$attrs.checked).toBe(
        propsData.requireCodeOwnersApproval,
      );
    });

    it('renders help text', () => {
      expect(findCodeOwnersApprovalCheckbox().text()).toContain(i18n.requireApprovalTitle);
      expect(findCodeOwnersApprovalCheckbox().text()).toContain(i18n.requireApprovalHelpText);
    });

    it('emits a change-allow-force-push event when changed', () => {
      findCodeOwnersApprovalCheckbox().vm.$emit('change', false);

      expect(wrapper.emitted('change-require-code-owners-approval')[0]).toEqual([false]);
    });
  });
});
