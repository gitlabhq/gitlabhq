import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import { sidebarData } from '../mock_data';

describe('SuperSidebar component', () => {
  let wrapper;

  const findUserBar = () => wrapper.findComponent(UserBar);

  afterEach(() => {
    wrapper.destroy();
  });

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
  });
});
