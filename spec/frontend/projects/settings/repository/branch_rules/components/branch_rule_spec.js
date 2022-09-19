import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRule, {
  i18n,
} from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';

const defaultProps = {
  name: 'main',
  isDefault: true,
  isProtected: true,
  approvalDetails: ['requires approval from TEST', '2 status checks'],
};

describe('Branch rule', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BranchRule, { propsData: { ...defaultProps, ...props } });
  };

  const findDefaultBadge = () => wrapper.findByText(i18n.defaultLabel);
  const findProtectedBadge = () => wrapper.findByText(i18n.protectedLabel);
  const findBranchName = () => wrapper.findByText(defaultProps.name);
  const findProtectionDetailsList = () => wrapper.findByRole('list');
  const findProtectionDetailsListItems = () => wrapper.findAllByRole('listitem');

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

    it('does not render protected badge if isProtected is set to false', () => {
      createComponent({ isProtected: false });
      expect(findProtectedBadge().exists()).toBe(false);
    });
  });

  it('does not render the protection details list of no details are present', () => {
    createComponent({ approvalDetails: null });
    expect(findProtectionDetailsList().exists()).toBe(false);
  });

  it('renders the protection details list items', () => {
    expect(findProtectionDetailsListItems().at(0).text()).toBe(defaultProps.approvalDetails[0]);
    expect(findProtectionDetailsListItems().at(1).text()).toBe(defaultProps.approvalDetails[1]);
  });
});
