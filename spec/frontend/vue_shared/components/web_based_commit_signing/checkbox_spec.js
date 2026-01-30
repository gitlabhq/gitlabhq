import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox, GlAlert } from '@gitlab/ui';
import WebBasedCommitSigningCheckbox from '~/vue_shared/components/web_based_commit_signing/checkbox.vue';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';

describe('WebBasedCommitSigningCheckbox', () => {
  let wrapper;

  const defaultProps = {
    initialValue: false,
    hasGroupPermissions: false,
    groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
    isGroupLevel: false,
    fullPath: 'gitlab-org',
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
  const findAlert = () => wrapper.findComponent(GlAlert);

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
    it('reflects the initialValue prop when unchecked', () => {
      expect(findCheckbox().props('checked')).toBe(false);
    });

    it('updates internal state when checkbox changes', async () => {
      await findCheckbox().vm.$emit('change', true);
      expect(wrapper.vm.isChecked).toBe(true);
    });

    it('reflects the initialValue prop when checked', () => {
      createComponent({ initialValue: true });
      expect(findCheckbox().props('checked')).toBe(true);
    });
  });

  describe('disabled state', () => {
    describe('for project level', () => {
      it('disables when group setting is enabled', () => {
        createComponent({
          isGroupLevel: false,
          groupWebBasedCommitSigningEnabled: true,
        });
        expect(findCheckbox().props('disabled')).toBe(true);
      });

      it('enables when group setting is disabled', () => {
        createComponent({
          isGroupLevel: false,
          groupWebBasedCommitSigningEnabled: false,
        });
        expect(findCheckbox().props('disabled')).toBe(false);
      });
    });
  });

  describe('error handling', () => {
    it('does not render alert by default', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders alert when there is an error', async () => {
      createComponent();
      // eslint-disable-next-line no-restricted-syntax
      await wrapper.setData({ errorMessage: 'An error occurred' });
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props('variant')).toBe('danger');
      expect(findAlert().text()).toBe('An error occurred');
    });

    it('dismisses error when alert is dismissed', async () => {
      createComponent();
      // eslint-disable-next-line no-restricted-syntax
      await wrapper.setData({ errorMessage: 'An error occurred' });
      expect(findAlert().exists()).toBe(true);

      await findAlert().vm.$emit('dismiss');
      expect(wrapper.vm.errorMessage).toBe('');
    });
  });

  describe('GroupInheritancePopover', () => {
    it('does not render popover when rendered on a group level', () => {
      createComponent({ isGroupLevel: true });
      expect(findPopover().exists()).toBe(false);
    });

    describe('when rendered on the project level', () => {
      it('renders popover with correct props', () => {
        createComponent({ isGroupLevel: false });
        expect(findPopover().exists()).toBe(true);
        expect(findPopover().props('hasGroupPermissions')).toBe(false);
        expect(findPopover().props('groupSettingsRepositoryPath')).toBe(
          '/groups/my-group/-/settings/repository',
        );
      });

      it('shows popover with correct props when user has no group permissions', () => {
        createComponent({ isGroupLevel: false, hasGroupPermissions: false });
        expect(findPopover().props()).toEqual({
          hasGroupPermissions: false,
          groupSettingsRepositoryPath: '/groups/my-group/-/settings/repository',
        });
      });
    });
  });
});
