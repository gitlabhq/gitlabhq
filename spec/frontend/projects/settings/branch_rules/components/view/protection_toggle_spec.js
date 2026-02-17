import { GlToggle, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DisabledByPolicyPopover from '~/projects/settings/branch_rules/components/view/disabled_by_policy_popover.vue';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';
import ProtectionToggle from '~/projects/settings/branch_rules/components/view/protection_toggle.vue';

describe('ProtectionToggle', () => {
  let wrapper;

  const createComponent = ({ props = {}, provided = {} } = {}) => {
    wrapper = shallowMountExtended(ProtectionToggle, {
      stubs: {
        GlToggle,
        GlIcon,
        GlLink,
        GlSprintf,
      },
      provide: {
        ...provided,
      },
      propsData: {
        dataTestIdPrefix: 'force-push',
        label: 'Force Push',
        iconTitle: 'icon title',
        isProtected: false,
        isLoading: false,
        ...props,
      },
    });
  };

  const findDisabledByPolicyPopover = () => wrapper.findComponent(DisabledByPolicyPopover);
  const findGroupInheritancePopover = () => wrapper.findComponent(GroupInheritancePopover);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findIcon = () => wrapper.findByTestId('force-push-icon');

  describe('when user can edit', () => {
    beforeEach(() => {
      createComponent({ provided: { canAdminProtectedBranches: true } });
    });

    it('renders the toggle', () => {
      expect(findToggle().exists()).toBe(true);
    });

    it('does not render the protection icon', () => {
      expect(findIcon().exists()).toBe(false);
    });

    it('does not render the toggle description when not provided', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('does not render group inheritance popover', () => {
      expect(findToggle().props('disabled')).toBe(false);
      expect(findGroupInheritancePopover().exists()).toBe(false);
    });

    it('does not render the disabled by policy popover', () => {
      expect(findToggle().props('disabled')).toBe(false);
      expect(findDisabledByPolicyPopover().exists()).toBe(false);
    });

    it('renders the toggle description, when protection is on', () => {
      createComponent({
        props: { isProtected: true, description: 'Some description' },
        provided: { canAdminProtectedBranches: true },
      });

      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });

    describe('when isGroupLevel is true', () => {
      it('renders group inheritance popover and disabled toggle, when protection is on', () => {
        createComponent({
          props: { isProtected: true, isGroupLevel: true },
          provided: { canAdminProtectedBranches: true },
        });

        expect(findToggle().props('disabled')).toBe(true);
        expect(findGroupInheritancePopover().exists()).toBe(true);
      });
    });

    describe('when protected by enforced security policies', () => {
      beforeEach(() => {
        createComponent({
          props: { isProtected: true, isProtectedByPolicy: true },
          provided: { canAdminProtectedBranches: true },
        });
      });

      it('renders disabled by policy popover and disabled toggle, when protection is on', () => {
        expect(findToggle().props('disabled')).toBe(true);
        expect(findDisabledByPolicyPopover().exists()).toBe(true);
      });
    });

    describe('when protected by warn mode security policies', () => {
      beforeEach(() => {
        createComponent({
          props: { isProtected: true, isProtectedByWarnPolicy: true },
          provided: { canAdminProtectedBranches: true },
        });
      });

      it('renders disabled by policy popover with warn mode', () => {
        expect(findDisabledByPolicyPopover().exists()).toBe(true);
        expect(findDisabledByPolicyPopover().props('isProtectedByPolicy')).toBe(false);
      });

      it('does not disable the toggle', () => {
        expect(findToggle().props('disabled')).toBe(false);
      });
    });
  });

  describe('when user can not edit', () => {
    beforeEach(() => {
      createComponent({ provided: { canAdminProtectedBranches: false } });
    });

    it('renders the icon instead of the toggle', () => {
      expect(findIcon().exists()).toBe(true);
    });

    it('does not render the toggle description when not provided', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('renders the toggle description, when protection is on', () => {
      createComponent({
        props: { isProtected: true, description: 'Some description' },
        provided: { canAdminProtectedBranches: false },
      });

      expect(wrapper.text()).toContain('Some description');
    });
  });
});
