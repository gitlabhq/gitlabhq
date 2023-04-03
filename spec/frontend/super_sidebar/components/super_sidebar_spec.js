import { nextTick } from 'vue';
import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import { SUPER_SIDEBAR_PEEK_DELAY } from '~/super_sidebar/constants';
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

  const findSidebar = () => wrapper.findByTestId('super-sidebar');
  const findHoverArea = () => wrapper.findByTestId('super-sidebar-hover-area');
  const findUserBar = () => wrapper.findComponent(UserBar);
  const findHelpCenter = () => wrapper.findComponent(HelpCenter);
  const findSidebarPortalTarget = () => wrapper.findComponent(SidebarPortalTarget);

  const createWrapper = ({ props = {}, isPeek = false } = {}) => {
    wrapper = shallowMountExtended(SuperSidebar, {
      data() {
        return {
          isPeek,
        };
      },
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

    it('updates inert attribute and `gl-visibility-hidden` class when peeking on hover', async () => {
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');
      isCollapsed.mockReturnValue(true);
      createWrapper();

      findHoverArea().trigger('mouseover');
      expect(setTimeoutSpy).toHaveBeenCalledTimes(1);
      expect(setTimeoutSpy).toHaveBeenLastCalledWith(
        expect.any(Function),
        SUPER_SIDEBAR_PEEK_DELAY,
      );
      jest.runAllTimers();
      await nextTick();

      expect(findSidebar().classes()).not.toContain('gl-visibility-hidden');
      expect(findSidebar().attributes('inert')).toBe(undefined);

      findSidebar().trigger('mouseleave');
      expect(setTimeoutSpy).toHaveBeenCalledTimes(2);
      expect(setTimeoutSpy).toHaveBeenLastCalledWith(
        expect.any(Function),
        SUPER_SIDEBAR_PEEK_DELAY,
      );
      jest.runAllTimers();
      await nextTick();

      expect(findSidebar().classes()).toContain('gl-visibility-hidden');
      expect(findSidebar().attributes('inert')).toBe('inert');
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
