import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox } from '@gitlab/ui';
import WebBasedCommitSigningCheckbox from '~/vue_shared/components/web_based_commit_signing/checkbox.vue';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';

describe('WebBasedCommitSigningCheckbox', () => {
  let wrapper;

  const defaultProps = {
    isChecked: false,
    hasGroupPermissions: false,
    groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
    isGroupLevel: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(WebBasedCommitSigningCheckbox, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlFormCheckbox,
      },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findPopover = () => wrapper.findComponent(GroupInheritancePopover);

  beforeEach(() => {
    createComponent();
  });

  it('renders the checkbox component', () => {
    expect(findCheckbox().exists()).toBe(true);
    expect(findCheckbox().text()).toContain('Sign web-based commits');
    expect(findCheckbox().text()).toContain(
      'Automatically sign commits made through the web interface.',
    );
    expect(findCheckbox().props('id')).toBe('web-based-commit-signing-checkbox');
  });

  describe('checkbox state', () => {
    it('reflects the isChecked prop when unchecked', () => {
      expect(findCheckbox().props('checked')).toBe(false);
    });

    it('emits update:isChecked event when checkbox changes', async () => {
      await findCheckbox().vm.$emit('change', true);
      expect(wrapper.emitted('update:isChecked')).toEqual([[true]]);
    });

    it('reflects the isChecked prop when checked', () => {
      createComponent({ isChecked: true });
      expect(findCheckbox().props('checked')).toBe(true);
    });
  });

  describe('disabled state', () => {
    beforeEach(() => {
      createComponent({ disabled: true });
    });

    it('disables the checkbox when disabled prop is true', () => {
      expect(findCheckbox().props('disabled')).toBe(true);
    });
  });

  describe('GroupInheritancePopover', () => {
    it('does not render popover when isGroupLevel is false', () => {
      createComponent({ isGroupLevel: false });
      expect(findPopover().exists()).toBe(false);
    });

    describe('when isGroupLevel is true', () => {
      it('renders popover with correct props', () => {
        createComponent({ isGroupLevel: true });
        expect(findPopover().exists()).toBe(true);
        expect(findPopover().props('hasGroupPermissions')).toBe(false);
        expect(findPopover().props('groupSettingsRepositoryPath')).toBe(
          '/groups/my-group/-/settings/repository',
        );
      });

      it('shows popover with correct props when user has no group permissions', () => {
        createComponent({ isGroupLevel: true, hasGroupPermissions: false });
        expect(findPopover().props()).toEqual({
          hasGroupPermissions: false,
          groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
        });
      });
    });
  });
});
