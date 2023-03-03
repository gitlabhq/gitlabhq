import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import { isCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import { sidebarData } from '../mock_data';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager', () => ({
  isCollapsed: jest.fn(),
}));

describe('SuperSidebar component', () => {
  let wrapper;

  const findSidebar = () => wrapper.find('.super-sidebar');
  const findUserBar = () => wrapper.findComponent(UserBar);
  const findHelpCenter = () => wrapper.findComponent(HelpCenter);
  const findSidebarPortalTarget = () => wrapper.findComponent(SidebarPortalTarget);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(SuperSidebar, {
      propsData: {
        sidebarData,
        ...props,
      },
    });
  };

  describe('default', () => {
    it('add aria-hidden and inert attributes when collapsed', () => {
      isCollapsed.mockReturnValue(true);
      createWrapper();
      expect(findSidebar().attributes('aria-hidden')).toBe('true');
      expect(findSidebar().attributes('inert')).toBe('inert');
    });

    it('does not add aria-hidden and inert attributes when expanded', () => {
      isCollapsed.mockReturnValue(false);
      createWrapper();
      expect(findSidebar().attributes('aria-hidden')).toBe('false');
      expect(findSidebar().attributes('inert')).toBe(undefined);
    });

    it('renders UserBar with sidebarData', () => {
      createWrapper();
      expect(findUserBar().props('sidebarData')).toBe(sidebarData);
    });

    it('renders HelpCenter with sidebarData', () => {
      createWrapper();
      expect(findHelpCenter().props('sidebarData')).toBe(sidebarData);
    });

    it('renders SidebarPortalTarget', () => {
      createWrapper();
      expect(findSidebarPortalTarget().exists()).toBe(true);
    });
  });
});
