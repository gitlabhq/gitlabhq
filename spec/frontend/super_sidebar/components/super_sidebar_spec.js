import { nextTick } from 'vue';
import { GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import {
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
} from '~/super_sidebar/constants';
import { stubComponent } from 'helpers/stub_component';
import { sidebarData } from '../mock_data';

const focusInputMock = jest.fn();

describe('SuperSidebar component', () => {
  let wrapper;

  const findSidebar = () => wrapper.findByTestId('super-sidebar');
  const findHoverArea = () => wrapper.findByTestId('super-sidebar-hover-area');
  const findUserBar = () => wrapper.findComponent(UserBar);
  const findHelpCenter = () => wrapper.findComponent(HelpCenter);
  const findSidebarPortalTarget = () => wrapper.findComponent(SidebarPortalTarget);

  const createWrapper = ({ props = {}, provide = {}, sidebarState = {} } = {}) => {
    wrapper = shallowMountExtended(SuperSidebar, {
      data() {
        return {
          ...sidebarState,
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
      provide,
    });
  };

  describe('default', () => {
    it('adds inert attribute when collapsed', () => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      expect(findSidebar().attributes('inert')).toBe('inert');
    });

    it('does not add inert attribute when expanded', () => {
      createWrapper();
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

  describe('when peeking on hover', () => {
    const peekClass = 'super-sidebar-peek';

    it('updates inert attribute and peek class', async () => {
      createWrapper({
        provide: { glFeatures: { superSidebarPeek: true } },
        sidebarState: { isCollapsed: true },
      });

      findHoverArea().trigger('mouseenter');

      jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);
      await nextTick();

      // Not quite enough time has elapsed yet for sidebar to open
      expect(findSidebar().classes()).not.toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe('inert');

      jest.advanceTimersByTime(1);
      await nextTick();

      // Exactly enough time has elapsed to open
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe(undefined);

      // Important: assume the cursor enters the sidebar
      findSidebar().trigger('mouseenter');

      jest.runAllTimers();
      await nextTick();

      // Sidebar remains peeked open indefinitely without a mouseleave
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe(undefined);

      findSidebar().trigger('mouseleave');

      jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);
      await nextTick();

      // Not quite enough time has elapsed yet for sidebar to hide
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe(undefined);

      jest.advanceTimersByTime(1);
      await nextTick();

      // Exactly enough time has elapsed for sidebar to hide
      expect(findSidebar().classes()).not.toContain('super-sidebar-peek');
      expect(findSidebar().attributes('inert')).toBe('inert');
    });

    it('eventually closes the sidebar if cursor never enters sidebar', async () => {
      createWrapper({
        provide: { glFeatures: { superSidebarPeek: true } },
        sidebarState: { isCollapsed: true },
      });

      findHoverArea().trigger('mouseenter');

      jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY);
      await nextTick();

      // Sidebar is now open
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe(undefined);

      // Important: do *not* fire a mouseenter event on the sidebar here. This
      // imitates what happens if the cursor moves away from the sidebar before
      // it actually appears.

      jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);
      await nextTick();

      // Not quite enough time has elapsed yet for sidebar to hide
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().attributes('inert')).toBe(undefined);

      jest.advanceTimersByTime(1);
      await nextTick();

      // Exactly enough time has elapsed for sidebar to hide
      expect(findSidebar().classes()).not.toContain('super-sidebar-peek');
      expect(findSidebar().attributes('inert')).toBe('inert');
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
