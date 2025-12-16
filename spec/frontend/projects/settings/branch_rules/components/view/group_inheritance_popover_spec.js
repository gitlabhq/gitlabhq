import { shallowMount } from '@vue/test-utils';
import { GlPopover, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import GroupInheritancePopover from '~/projects/settings/branch_rules/components/view/group_inheritance_popover.vue';

describe('GroupInheritancePopover', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMount(GroupInheritancePopover, {
      stubs: {
        GlSprintf,
      },
      provide: {
        canAdminGroupProtectedBranches: false,
        groupSettingsRepositoryPath: '/groups/test-group/-/settings/repository',
        ...provide,
      },
    });
  };

  const findTriggerButton = () => wrapper.find('button');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders the lock icon', () => {
    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('lock');
    expect(findIcon().props('variant')).toBe('disabled');
  });

  it('renders the popover with correct props', () => {
    expect(findPopover().exists()).toBe(true);
    expect(findPopover().props('triggers')).toBe('hover focus');
    expect(findPopover().props('title')).toBe('Setting inherited');
    expect(findPopover().props('target')).toMatch(/^group-level-inheritance-info-/);
  });

  it('renders the help link with correct href', () => {
    expect(findLink().exists()).toBe(true);
    expect(findLink().attributes('href')).toBe('/help/user/permissions#group-repositories');
  });

  describe('when user cannot admin group protected branches', () => {
    it('shows the default description message', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().text()).toBe(
        'This setting is configured for the group. To make changes, contact a user with required permissions.',
      );
    });

    it('links to the permissions help documentation', () => {
      expect(findLink().attributes('href')).toBe('/help/user/permissions#group-repositories');
    });

    it('renders the trigger button with correct attributes', () => {
      expect(findTriggerButton().exists()).toBe(true);
      expect(findTriggerButton().attributes('aria-label')).toBe(
        'Setting inherited. This setting is configured for the group. To make changes, contact a user with required permissions.',
      );
    });
  });

  describe('when user can admin group protected branches', () => {
    beforeEach(() => {
      createComponent({ canAdminGroupProtectedBranches: true });
    });

    it('shows the editable description message', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().text()).toBe(
        'This setting is configured for the group. To make changes, go to group repository settings.',
      );
    });

    it('links to the group repository settings', () => {
      expect(findLink().attributes('href')).toBe('/groups/test-group/-/settings/repository');
    });

    it('renders the trigger button with correct attributes', () => {
      expect(findTriggerButton().exists()).toBe(true);
      expect(findTriggerButton().attributes('aria-label')).toBe(
        'Setting inherited. This setting is configured for the group. To make changes, go to group repository settings.',
      );
    });
  });
});
