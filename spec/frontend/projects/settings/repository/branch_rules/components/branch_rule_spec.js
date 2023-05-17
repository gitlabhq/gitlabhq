import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRule, {
  i18n,
} from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import { sprintf, n__ } from '~/locale';
import {
  branchRuleProvideMock,
  branchRulePropsMock,
  branchRuleWithoutDetailsPropsMock,
} from '../mock_data';

describe('Branch rule', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BranchRule, {
      provide: branchRuleProvideMock,
      propsData: { ...branchRulePropsMock, ...props },
    });
  };

  const findDefaultBadge = () => wrapper.findByText(i18n.defaultLabel);
  const findProtectedBadge = () => wrapper.findByText(i18n.protectedLabel);
  const findBranchName = () => wrapper.findByText(branchRulePropsMock.name);
  const findProtectionDetailsList = () => wrapper.findByRole('list');
  const findProtectionDetailsListItems = () => wrapper.findAllByRole('listitem');
  const findDetailsButton = () => wrapper.findByText(i18n.detailsButtonLabel);

  beforeEach(() => createComponent());

  it('renders the branch name', () => {
    expect(findBranchName().exists()).toBe(true);
  });

  describe('badges', () => {
    it('renders both default and protected badges', () => {
      expect(findDefaultBadge().exists()).toBe(true);
      expect(findProtectedBadge().exists()).toBe(true);
    });

    it('does not render default badge if isDefault is set to false', () => {
      createComponent({ isDefault: false });
      expect(findDefaultBadge().exists()).toBe(false);
    });

    it('does not render default badge if branchProtection is null', () => {
      createComponent(branchRuleWithoutDetailsPropsMock);
      expect(findProtectedBadge().exists()).toBe(false);
    });
  });

  it('does not render the protection details list when branchProtection is null', () => {
    createComponent(branchRuleWithoutDetailsPropsMock);
    expect(findProtectionDetailsList().exists()).toBe(false);
  });

  it('renders the protection details list items', () => {
    expect(findProtectionDetailsListItems()).toHaveLength(wrapper.vm.approvalDetails.length);
    expect(findProtectionDetailsListItems().at(0).text()).toBe(i18n.allowForcePush);
    expect(findProtectionDetailsListItems().at(1).text()).toBe(wrapper.vm.pushAccessLevelsText);
  });

  it('renders branches count for wildcards', () => {
    createComponent({ name: 'test-*' });
    expect(findProtectionDetailsListItems().at(0).text()).toMatchInterpolatedText(
      sprintf(i18n.matchingBranches, {
        total: branchRulePropsMock.matchingBranchesCount,
        subject: n__('branch', 'branches', branchRulePropsMock.matchingBranchesCount),
      }),
    );
  });

  it('renders a detail button with the correct href', () => {
    const encodedBranchName = encodeURIComponent(branchRulePropsMock.name);

    expect(findDetailsButton().attributes('href')).toBe(
      `${branchRuleProvideMock.branchRulesPath}?branch=${encodedBranchName}`,
    );
  });
});
