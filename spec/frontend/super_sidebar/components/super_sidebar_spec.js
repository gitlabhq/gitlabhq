import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import { isCollapsed } from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import { stubComponent } from 'helpers/stub_component';
import { sidebarData } from '../mock_data';

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager', () => ({
  isCollapsed: jest.fn(),
}));
const focusInputMock = jest.fn();

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
      stubs: {
        ContextSwitcher: stubComponent(ContextSwitcher, {
          methods: { focusInput: focusInputMock },
        }),
      },
    });
  };

  describe('default', () => {
    it('adds inert attribute and `gl-visibility-hidden` class when collapsed', () => {
      isCollapsed.mockReturnValue(true);
      createWrapper();
      expect(findSidebar().classes()).toContain('gl-visibility-hidden');
      expect(findSidebar().attributes('inert')).toBe('inert');
    });

    it('does not add inert attribute and `gl-visibility-hidden` class when expanded', () => {
      isCollapsed.mockReturnValue(false);
      createWrapper();
      expect(findSidebar().classes()).not.toContain('gl-visibility-hidden');
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

    it("does not call the context switcher's focusInput method initially", () => {
      createWrapper();

      expect(focusInputMock).not.toHaveBeenCalled();
    });

    it('renders hidden shortcut links', () => {
      createWrapper();
      const [linkAttrs] = sidebarData.shortcut_links;
      const link = wrapper.find(`.${linkAttrs.css_class}`);

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(linkAttrs.href);
      expect(link.attributes('class')).toContain('gl-display-none');
    });
  });

  describe('when opening the context switcher', () => {
    beforeEach(() => {
      createWrapper();
      wrapper.findComponent(GlCollapse).vm.$emit('input', true);
      wrapper.findComponent(GlCollapse).vm.$emit('shown');
    });

    it("calls the context switcher's focusInput method", () => {
      expect(focusInputMock).toHaveBeenCalledTimes(1);
    });
  });
});
