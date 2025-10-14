import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlPopover } from '@gitlab/ui';
import GroupBadge from '~/projects/settings/repository/branch_rules/components/group_badge.vue';

describe('GroupBadge', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GroupBadge);
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findWrapper = () => wrapper.find('button');

  describe('when isGroupLevel is true', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the wrapper button with accessible text alternative', () => {
      expect(findWrapper().exists()).toBe(true);
      expect(findWrapper().attributes('aria-label')).toBe(
        'Inherited branch rule. This branch rule is inherited from the group Protected branches settings.',
      );
    });

    it('renders the badge with correct props and styling', () => {
      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props('variant')).toBe('tier');
      expect(findBadge().text()).toBe('group');
    });

    it('renders the popover with correct props', () => {
      expect(findPopover().exists()).toBe(true);
      expect(findPopover().props('title')).toBe('Inherited branch rule');
      expect(findPopover().text()).toBe(
        'This branch rule is inherited from the group Protected branches settings.',
      );
    });

    it('connects the popover to the badge via target', () => {
      const badgeId = findWrapper().attributes('id');
      expect(findPopover().props('target')).toBe(badgeId);
    });
  });
});
