import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import Protection, { i18n } from '~/projects/settings/branch_rules/components/view/protection.vue';
import ProtectionRow from '~/projects/settings/branch_rules/components/view/protection_row.vue';
import DisabledByPolicyPopover from '~/projects/settings/branch_rules/components/view/disabled_by_policy_popover.vue';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';
import { protectionPropsMock, protectionEmptyStatePropsMock, deployKeysMock } from './mock_data';

describe('Branch rule protection', () => {
  let wrapper;

  const createComponent = (props = protectionPropsMock) => {
    wrapper = shallowMountExtended(Protection, {
      propsData: {
        header: 'Allowed to merge',
        headerLinkHref: '/foo/bar',
        headerLinkTitle: 'Manage here',
        emptyStateCopy: 'Nothing to show',
        ...props,
      },
      stubs: {
        CrudComponent,
        GroupInheritancePopover: {
          template: '<div>Stubbed GroupInheritancePopover</div>',
        },
      },
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
      stubs: {
        CrudComponent,
        GroupInheritancePopover: {
          template: '<div>Stubbed GroupInheritancePopover</div>',
        },
      },
    });
  };

  beforeEach(() => createComponent());

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findDisabledByPolicyPopover = () => wrapper.findComponent(DisabledByPolicyPopover);
  const findGroupInheritancePopover = () => wrapper.findComponent(GroupInheritancePopover);
  const findHeader = () => wrapper.findByText(protectionPropsMock.header);
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
    createComponent({ ...protectionEmptyStatePropsMock });

    expect(findEmptyState().text()).toBe('No status checks');
  });

  it('renders a help text when provided', () => {
    createComponent({ helpText: 'Help text' });

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
    createComponent({ ...protectionPropsMock, deployKeys: deployKeysMock });
    expect(findProtectionRows().at(2).props()).toMatchObject({
      showDivider: true,
      deployKeys: deployKeysMock,
      title: i18n.deployKeysTitle,
    });
  });

  describe('When `isEditAvailable` prop is set to true', () => {
    it('renders `Edit` button', () => {
      createComponent({ isEditAvailable: true });
      expect(findEditButton().exists()).toBe(true);
    });

    it('does not render group inheritance popover', () => {
      createComponent({ isEditAvailable: true });
      expect(findEditButton().props('disabled')).toBe(false);
      expect(findGroupInheritancePopover().exists()).toBe(false);
    });

    describe('when `isGroupLevel` is true', () => {
      it('renders group inheritance popover and disabled `Edit` button, when protection is on', () => {
        createComponent({ isGroupLevel: true, isEditAvailable: true });

        expect(findEditButton().props('disabled')).toBe(true);
        expect(findGroupInheritancePopover().exists()).toBe(true);
      });
    });

    describe('when protected by enforced security policies', () => {
      beforeEach(() => {
        createComponent({ isEditAvailable: true, isProtectedByPolicy: true });
      });

      it('renders disabled by policy popover and disabled `Edit` button, when protection is on', () => {
        expect(findEditButton().props('disabled')).toBe(true);
        expect(findDisabledByPolicyPopover().exists()).toBe(true);
      });
    });

    describe('when protected by warn mode security policies', () => {
      beforeEach(() => {
        createComponent({ isEditAvailable: true, isProtectedByWarnPolicy: true });
      });

      it('renders disabled by policy popover with warn mode', () => {
        expect(findDisabledByPolicyPopover().exists()).toBe(true);
        expect(findDisabledByPolicyPopover().props('isProtectedByPolicy')).toBe(false);
      });

      it('does not disable the `Edit` button', () => {
        expect(findEditButton().props('disabled')).toBe(false);
      });
    });
  });

  describe('description slot', () => {
    it('renders help text when no description slot is provided', () => {
      const helpText = 'This is help text';
      createComponent({ helpText });

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
