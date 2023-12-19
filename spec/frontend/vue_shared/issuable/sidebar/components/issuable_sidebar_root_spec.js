import { GlButton, GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { nextTick } from 'vue';
import Cookies from '~/lib/utils/cookies';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import IssuableSidebarRoot from '~/vue_shared/issuable/sidebar/components/issuable_sidebar_root.vue';
import { USER_COLLAPSED_GUTTER_COOKIE } from '~/vue_shared/issuable/sidebar/constants';

const MOCK_LAYOUT_PAGE_CLASS = 'layout-page';

const createComponent = () => {
  setHTMLFixture(`<div class="${MOCK_LAYOUT_PAGE_CLASS}"></div>`);

  return shallowMountExtended(IssuableSidebarRoot, {
    slots: {
      'right-sidebar-items': `
        <button class="js-todo">Todo</button>
      `,
    },
    stubs: {
      GlButton,
      GlIcon,
    },
  });
};

describe('IssuableSidebarRoot', () => {
  let wrapper;

  const findToggleSidebarButton = () => wrapper.findByTestId('toggle-right-sidebar-button');

  const assertPageLayoutClasses = ({ isExpanded }) => {
    const { classList } = document.querySelector(`.${MOCK_LAYOUT_PAGE_CLASS}`);
    if (isExpanded) {
      expect(classList).toContain('right-sidebar-expanded');
      expect(classList).not.toContain('right-sidebar-collapsed');
    } else {
      expect(classList).toContain('right-sidebar-collapsed');
      expect(classList).not.toContain('right-sidebar-expanded');
    }
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when sidebar is expanded', () => {
    beforeEach(() => {
      jest.spyOn(Cookies, 'set').mockImplementation(jest.fn());
      jest.spyOn(Cookies, 'get').mockReturnValue(false);
      jest.spyOn(bp, 'isDesktop').mockReturnValue(true);

      wrapper = createComponent();
    });

    it('renders component container element with class `right-sidebar-expanded`', () => {
      expect(wrapper.classes()).toContain('right-sidebar-expanded');
    });

    it('sets layout class to reflect expanded state', () => {
      assertPageLayoutClasses({ isExpanded: true });
    });

    it('renders sidebar toggle button with text and icon', () => {
      const buttonEl = findToggleSidebarButton();

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.attributes('title')).toBe('Collapse sidebar');
      expect(wrapper.findByTestId('chevron-double-lg-right-icon').isVisible()).toBe(true);
    });

    describe('when collapsing the sidebar', () => {
      it('updates "collapsed_gutter" cookie value and layout classes', async () => {
        await findToggleSidebarButton().trigger('click');

        expect(Cookies.set).toHaveBeenCalledWith(USER_COLLAPSED_GUTTER_COOKIE, true, {
          expires: 365,
          secure: false,
        });
        assertPageLayoutClasses({ isExpanded: false });
      });
    });

    describe('when window `resize` event is triggered', () => {
      it.each`
        breakpoint | isExpandedValue
        ${'xs'}    | ${false}
        ${'sm'}    | ${false}
        ${'md'}    | ${false}
        ${'lg'}    | ${true}
        ${'xl'}    | ${true}
      `(
        'sets page layout classes correctly when current screen size is `$breakpoint`',
        async ({ breakpoint, isExpandedValue }) => {
          jest.spyOn(bp, 'isDesktop').mockReturnValue(breakpoint === 'lg' || breakpoint === 'xl');

          window.dispatchEvent(new Event('resize'));
          await nextTick();

          assertPageLayoutClasses({ isExpanded: isExpandedValue });
        },
      );
    });
  });

  describe('when sidebar is collapsed', () => {
    beforeEach(() => {
      jest.spyOn(Cookies, 'get').mockReturnValue(true);

      wrapper = createComponent();
    });

    it('renders component container element with class `right-sidebar-collapsed`', () => {
      expect(wrapper.classes()).toContain('right-sidebar-collapsed');
    });

    it('sets layout class to reflect collapsed state', () => {
      assertPageLayoutClasses({ isExpanded: false });
    });

    it('renders sidebar toggle button with title and icon', () => {
      const buttonEl = findToggleSidebarButton();

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.attributes('title')).toBe('Expand sidebar');
      expect(wrapper.findByTestId('chevron-double-lg-left-icon').isVisible()).toBe(true);
    });
  });

  it('renders slotted sidebar items', () => {
    wrapper = createComponent();

    const sidebarItemsEl = wrapper.findByTestId('sidebar-items');

    expect(sidebarItemsEl.exists()).toBe(true);
    expect(sidebarItemsEl.find('button.js-todo').exists()).toBe(true);
  });
});
