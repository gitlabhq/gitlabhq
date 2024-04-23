import { GlCard, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Protection, { i18n } from '~/projects/settings/branch_rules/components/view/protection.vue';
import ProtectionRow from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import { protectionPropsMock } from './mock_data';

describe('Branch rule protection', () => {
  let wrapper;

  const createComponent = (glFeatures = { editBranchRules: true }, props = {}) => {
    wrapper = shallowMountExtended(Protection, {
      propsData: {
        ...props,
        ...protectionPropsMock,
      },
      stubs: { GlCard },
      provide: { glFeatures },
    });
  };

  beforeEach(() => createComponent());

  const findCard = () => wrapper.findComponent(GlCard);
  const findHeader = () => wrapper.findByText(protectionPropsMock.header);
  const findLink = () => wrapper.findComponent(GlLink);
  const findProtectionRows = () => wrapper.findAllComponents(ProtectionRow);
  const findEditButton = () => wrapper.findByTestId('edit-button');

  it('renders a card component', () => {
    expect(findCard().exists()).toBe(true);
  });

  it('renders a header', () => {
    expect(findHeader().exists()).toBe(true);
  });

  it('renders link  when `edit_branch_rules` FF is enabled and `isEditAvailable` prop is false', () => {
    expect(findLink().text()).toBe(protectionPropsMock.headerLinkTitle);
    expect(findLink().attributes('href')).toBe(protectionPropsMock.headerLinkHref);
  });

  describe('When `isEditAvailable` prop is set to true and `edit_branch_rules` FF is enabled', () => {
    beforeEach(() => createComponent({ editBranchRules: true }, { isEditAvailable: true }));
    it('renders `Edit` button', () => {
      expect(findEditButton().exists()).toBe(true);
    });
  });

  describe('When `edit_branch_rules` FF is disabled', () => {
    beforeEach(() => createComponent({ editBranchRules: false }));

    it('does not render `Edit` button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('renders link to manage branch protections', () => {
      expect(findLink().text()).toBe(protectionPropsMock.headerLinkTitle);
      expect(findLink().attributes('href')).toBe(protectionPropsMock.headerLinkHref);
    });
  });

  it('renders a protection row for roles', () => {
    expect(findProtectionRows().at(0).props()).toMatchObject({
      accessLevels: protectionPropsMock.roles,
      showDivider: false,
      title: i18n.rolesTitle,
    });
  });

  it('renders a protection row for users', () => {
    expect(findProtectionRows().at(1).props()).toMatchObject({
      users: protectionPropsMock.users,
      showDivider: true,
      title: i18n.usersTitle,
    });
  });

  it('renders a protection row for groups', () => {
    expect(findProtectionRows().at(2).props()).toMatchObject({
      accessLevels: protectionPropsMock.groups,
      showDivider: true,
      title: i18n.groupsTitle,
    });
  });

  it('renders a protection row for approvals', () => {
    const approval = protectionPropsMock.approvals[0];
    expect(findProtectionRows().at(3).props()).toMatchObject({
      title: approval.name,
      users: approval.eligibleApprovers.nodes,
      approvalsRequired: approval.approvalsRequired,
    });
  });

  it('renders a protection row for status checks', () => {
    const statusCheck = protectionPropsMock.statusChecks[0];
    expect(findProtectionRows().at(4).props()).toMatchObject({
      title: statusCheck.name,
      showDivider: false,
      statusCheckUrl: statusCheck.externalUrl,
    });

    expect(findProtectionRows().at(5).props('showDivider')).toBe(true);
  });
});
