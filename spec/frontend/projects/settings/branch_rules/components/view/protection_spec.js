import { GlCard, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Protection, { i18n } from '~/projects/settings/branch_rules/components/view/protection.vue';
import ProtectionRow from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import { protectionPropsMock } from './mock_data';

describe('Branch rule protection', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(Protection, {
      propsData: protectionPropsMock,
      stubs: { GlCard },
    });
  };

  beforeEach(() => createComponent());

  const findCard = () => wrapper.findComponent(GlCard);
  const findHeader = () => wrapper.findByText(protectionPropsMock.header);
  const findLink = () => wrapper.findComponent(GlLink);
  const findProtectionRows = () => wrapper.findAllComponents(ProtectionRow);

  it('renders a card component', () => {
    expect(findCard().exists()).toBe(true);
  });

  it('renders a header with a link', () => {
    expect(findHeader().exists()).toBe(true);
    expect(findLink().text()).toBe(protectionPropsMock.headerLinkTitle);
    expect(findLink().attributes('href')).toBe(protectionPropsMock.headerLinkHref);
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
