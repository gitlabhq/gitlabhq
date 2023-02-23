import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import { sidebarData } from '../mock_data';

describe('SuperSidebar component', () => {
  let wrapper;

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
    beforeEach(() => {
      createWrapper();
    });

    it('renders UserBar with sidebarData', () => {
      expect(findUserBar().props('sidebarData')).toBe(sidebarData);
    });

    it('renders HelpCenter with sidebarData', () => {
      expect(findHelpCenter().props('sidebarData')).toBe(sidebarData);
    });

    it('renders SidebarPortalTarget', () => {
      expect(findSidebarPortalTarget().exists()).toBe(true);
    });
  });
});
