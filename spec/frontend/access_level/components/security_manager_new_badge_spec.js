import { GlBadge, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SecurityManagerNewBadge from '~/access_level/components/security_manager_new_badge.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

describe('SecurityManagerNewBadge', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(SecurityManagerNewBadge);
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findHelpLink = () => findPopover().findComponent(HelpPageLink);

  beforeEach(() => {
    createComponent();
  });

  it('renders the "New" badge', () => {
    const badge = findBadge();

    expect(badge.attributes('id')).toBe('security-manager-role-badge');
    expect(badge.props('variant')).toBe('info');
    expect(badge.text()).toContain('New');
  });

  it('renders a popover targeting the badge', () => {
    const popover = findPopover();

    expect(popover.props('target')).toBe('security-manager-role-badge');
    expect(popover.props('title')).toBe('Security Manager role now available');
    expect(popover.text()).toContain(
      'The Security Manager role provides comprehensive access to security features',
    );
  });

  it('renders a "Learn more" help page link inside the popover', () => {
    const link = findHelpLink();

    expect(link.text()).toBe('Learn more.');
    expect(link.props('href')).toBe('user/permissions');
    expect(link.attributes('target')).toBe('_blank');
  });
});
