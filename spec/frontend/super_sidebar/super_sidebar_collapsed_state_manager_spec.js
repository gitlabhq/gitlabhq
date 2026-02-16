import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { sidebarState } from '~/super_sidebar/constants';
import {
  SIDEBAR_COLLAPSED_CLASS,
  SIDEBAR_COLLAPSED_COOKIE,
  SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
  toggleSuperSidebarCollapsed,
  toggleSuperSidebarIconOnly,
  initSuperSidebarCollapsedState,
  findPage,
  bindSuperSidebarCollapsedEvents,
} from '~/super_sidebar/super_sidebar_collapsed_state_manager';

const { xl, sm } = breakpoints;

jest.mock('~/lib/utils/common_utils', () => ({
  getCookie: jest.fn(),
  setCookie: jest.fn(),
}));

const pageHasCollapsedClass = (hasClass) => {
  if (hasClass) {
    expect(findPage().classList).toContain(SIDEBAR_COLLAPSED_CLASS);
  } else {
    expect(findPage().classList).not.toContain(SIDEBAR_COLLAPSED_CLASS);
  }
};

describe('Super Sidebar Collapsed State Manager', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="page-with-super-sidebar">
        <aside class="super-sidebar"></aside>
      </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('toggleSuperSidebarCollapsed', () => {
    it('does not save cookie', () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);

      toggleSuperSidebarCollapsed(true);

      pageHasCollapsedClass(true);
      expect(setCookie).not.toHaveBeenCalled();
    });
  });

  describe('initSuperSidebarCollapsedState', () => {
    it('does not collapse sidebar on desktop', () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);
      getCookie.mockReturnValue('true');

      initSuperSidebarCollapsedState();

      expect(findPage().classList).not.toContain(SIDEBAR_COLLAPSED_CLASS);
      expect(sidebarState.isCollapsed).toBe(false);
    });

    it('sets only `isIconOnly` (not `isCollapsed`) to true when cookie is true', () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);
      getCookie.mockReturnValue('true');

      initSuperSidebarCollapsedState();

      expect(sidebarState.isIconOnly).toBe(true);
      expect(sidebarState.isCollapsed).toBe(false);
    });

    it('sets `isIconOnly` to false when cookie is false', () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);
      getCookie.mockReturnValue('false');

      initSuperSidebarCollapsedState();

      expect(sidebarState.isIconOnly).toBe(false);
      expect(sidebarState.isCollapsed).toBe(false);
    });
  });

  describe('bindSuperSidebarCollapsedEvents', () => {
    describe('handles width change', () => {
      let removeEventListener;

      afterEach(() => {
        removeEventListener();
      });

      it.each`
        initialWindowWidth | updatedWindowWidth | hasClassBeforeResize | hasClassAfterResize
        ${xl}              | ${sm}              | ${false}             | ${true}
        ${sm}              | ${xl}              | ${true}              | ${false}
        ${xl}              | ${xl}              | ${false}             | ${false}
        ${sm}              | ${sm}              | ${true}              | ${true}
      `(
        'when changing width from $initialWindowWidth to $updatedWindowWidth expect page to have collapsed class before resize to be $hasClassBeforeResize and after resize to be $hasClassAfterResize',
        ({ initialWindowWidth, updatedWindowWidth, hasClassBeforeResize, hasClassAfterResize }) => {
          getCookie.mockReturnValue(undefined);
          window.innerWidth = initialWindowWidth;
          initSuperSidebarCollapsedState();

          pageHasCollapsedClass(hasClassBeforeResize);

          removeEventListener = bindSuperSidebarCollapsedEvents();

          window.innerWidth = updatedWindowWidth;
          window.dispatchEvent(new Event('resize'));

          pageHasCollapsedClass(hasClassAfterResize);
        },
      );
    });
  });

  describe('toggleSuperSidebarIconOnly', () => {
    beforeEach(() => {
      sidebarState.isIconOnly = false;
    });

    it('toggles isIconOnly state when called without parameters', () => {
      toggleSuperSidebarIconOnly();
      expect(sidebarState.isIconOnly).toBe(true);

      toggleSuperSidebarIconOnly();
      expect(sidebarState.isIconOnly).toBe(false);
    });

    it('sets isIconOnly to specific value when provided', () => {
      toggleSuperSidebarIconOnly(true);

      expect(sidebarState.isIconOnly).toBe(true);
    });

    it('saves toggle state as cookie', () => {
      toggleSuperSidebarIconOnly(false);

      expect(setCookie).toHaveBeenCalledWith(SIDEBAR_COLLAPSED_COOKIE, false, {
        expires: SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
      });
    });
  });
});
