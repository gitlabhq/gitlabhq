import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import Protection, { i18n } from '~/projects/settings/branch_rules/components/view/protection.vue';
import ProtectionRow from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import {
  protectionPropsMock,
  protectionEmptyStatePropsMock,
  statusChecksRulesMock,
  deployKeysMock,
} from './mock_data';

describe('Branch rule protection', () => {
  let wrapper;

  const createComponent = (glFeatures = { editBranchRules: true }, props = protectionPropsMock) => {
    wrapper = shallowMountExtended(Protection, {
      propsData: {
        header: 'Allowed to merge',
        headerLinkHref: '/foo/bar',
        headerLinkTitle: 'Manage here',
        emptyStateCopy: 'Nothing to show',
        ...props,
      },
      stubs: { CrudComponent },
      provide: { glFeatures },
    });
  };

  const createComponentWithSlot = (slotName, slotContent, props = {}) => {
    wrapper = shallowMountExtended(Protection, {
      propsData: {
        ...protectionPropsMock,
        ...props,
      },
      slots: {
        [slotName]: slotContent,
      },
      stubs: { CrudComponent },
      provide: { glFeatures: { editBranchRules: true } },
    });
  };

  beforeEach(() => createComponent());

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findHeader = () => wrapper.findByText(protectionPropsMock.header);
  const findLink = () => wrapper.findComponent(GlLink);
  const findProtectionRows = () => wrapper.findAllComponents(ProtectionRow);
  const findEmptyState = () => wrapper.findByTestId('protection-empty-state');
  const findEditButton = () => wrapper.findByTestId('edit-rule-button');

  it('renders a crud component', () => {
    expect(findCrudComponent().exists()).toBe(true);
  });

  it('renders a header', () => {
    expect(findHeader().exists()).toBe(true);
  });

  it('renders empty state for Status Checks when there is none', () => {
    createComponent({ editBranchRules: true }, { ...protectionEmptyStatePropsMock });

    expect(findEmptyState().text()).toBe('No status checks');
  });

  it('renders a help text when provided', () => {
    createComponent({ editBranchRules: true }, { helpText: 'Help text' });

    expect(findCrudComponent().text()).toContain('Help text');
  });

  it('renders a protection row for roles', () => {
    expect(findProtectionRows().at(0).props()).toMatchObject({
      accessLevels: protectionPropsMock.roles,
      showDivider: false,
      title: i18n.rolesTitle,
    });
  });

  it('renders a protection row for users and groups', () => {
    expect(findProtectionRows().at(1).props()).toMatchObject({
      showDivider: true,
      groups: protectionPropsMock.groups,
      users: protectionPropsMock.users,
      title: i18n.usersAndGroupsTitle,
    });
  });

  it('renders a protection row for deploy keys', () => {
    createComponent(
      { editBranchRules: false },
      { ...protectionPropsMock, deployKeys: deployKeysMock },
    );
    expect(findProtectionRows().at(2).props()).toMatchObject({
      showDivider: true,
      deployKeys: deployKeysMock,
      title: i18n.deployKeysTitle,
    });
  });

  describe('When `isEditAvailable` prop is set to true', () => {
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

    it('renders a protection row for status checks', () => {
      createComponent({ editBranchRules: false }, { statusChecks: statusChecksRulesMock });
      const statusCheck = statusChecksRulesMock[0];
      expect(findProtectionRows().at(0).props()).toMatchObject({
        title: statusCheck.name,
        showDivider: false,
        statusCheckUrl: statusCheck.externalUrl,
      });

      expect(findProtectionRows().at(1).props('showDivider')).toBe(true);
    });
  });

  describe('description slot', () => {
    it('renders help text when no description slot is provided', () => {
      const helpText = 'This is help text';
      createComponent({ editBranchRules: true }, { helpText });

      expect(findCrudComponent().text()).toContain(helpText);
    });

    it('renders description slot content when provided', () => {
      const slotContent = 'Custom description content';
      createComponentWithSlot('description', slotContent, {
        helpText: 'Help text that should not show',
      });

      expect(findCrudComponent().text()).toContain(slotContent);
      expect(findCrudComponent().text()).not.toContain('Help text that should not show');
    });
  });

  describe('content slot', () => {
    it('renders content slot when provided', () => {
      const slotContent = 'Custom content';
      createComponentWithSlot('content', slotContent);

      expect(wrapper.text()).toContain(slotContent);
    });

    it('does not show empty state when content slot is provided', () => {
      createComponentWithSlot('content', 'Custom content', protectionEmptyStatePropsMock);

      expect(findEmptyState().exists()).toBe(false);
    });
  });
});
