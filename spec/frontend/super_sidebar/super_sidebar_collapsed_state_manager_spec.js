import { GlBreakpointInstance as bp, breakpoints } from '@gitlab/ui/dist/utils';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { sidebarState } from '~/super_sidebar/constants';
import {
  SIDEBAR_COLLAPSED_CLASS,
  SIDEBAR_COLLAPSED_COOKIE,
  SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
  toggleSuperSidebarCollapsed,
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
    it.each`
      collapsed | saveCookie | windowWidth | hasClass
      ${true}   | ${true}    | ${xl}       | ${true}
      ${true}   | ${false}   | ${xl}       | ${true}
      ${true}   | ${true}    | ${sm}       | ${true}
      ${true}   | ${false}   | ${sm}       | ${true}
      ${false}  | ${true}    | ${xl}       | ${false}
      ${false}  | ${false}   | ${xl}       | ${false}
      ${false}  | ${true}    | ${sm}       | ${false}
      ${false}  | ${false}   | ${sm}       | ${false}
    `(
      'when collapsed is $collapsed, saveCookie is $saveCookie, and windowWidth is $windowWidth then page class contains `page-with-super-sidebar-collapsed` is $hasClass',
      ({ collapsed, saveCookie, windowWidth, hasClass }) => {
        jest.spyOn(bp, 'windowWidth').mockReturnValue(windowWidth);

        toggleSuperSidebarCollapsed(collapsed, saveCookie);

        pageHasCollapsedClass(hasClass);
        expect(sidebarState.isCollapsed).toBe(collapsed);

        if (saveCookie && windowWidth >= xl) {
          expect(setCookie).toHaveBeenCalledWith(SIDEBAR_COLLAPSED_COOKIE, collapsed, {
            expires: SIDEBAR_COLLAPSED_COOKIE_EXPIRATION,
          });
        } else {
          expect(setCookie).not.toHaveBeenCalled();
        }
      },
    );
  });

  describe('initSuperSidebarCollapsedState', () => {
    it.each`
      windowWidth | cookie       | hasClass
      ${xl}       | ${undefined} | ${false}
      ${sm}       | ${undefined} | ${true}
      ${xl}       | ${'true'}    | ${true}
      ${sm}       | ${'true'}    | ${true}
    `(
      'sets page class to `page-with-super-sidebar-collapsed` when windowWidth is $windowWidth and cookie value is $cookie',
      ({ windowWidth, cookie, hasClass }) => {
        jest.spyOn(bp, 'windowWidth').mockReturnValue(windowWidth);
        getCookie.mockReturnValue(cookie);

        initSuperSidebarCollapsedState();

        pageHasCollapsedClass(hasClass);
        expect(setCookie).not.toHaveBeenCalled();
      },
    );
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
});
