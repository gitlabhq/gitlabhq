import { nextTick } from 'vue';
import { GlBreakpointInstance as bp, breakpoints } from '@gitlab/ui/dist/utils';
import ExtraInfo from 'jh_else_ce/super_sidebar/components/extra_info.vue';
import { Mousetrap } from '~/lib/mousetrap';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import UserBar from '~/super_sidebar/components/user_bar.vue';
import SidebarPeekBehavior from '~/super_sidebar/components/sidebar_peek_behavior.vue';
import SidebarHoverPeekBehavior from '~/super_sidebar/components/sidebar_hover_peek_behavior.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import {
  sidebarState,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_WILL_CLOSE as STATE_WILL_CLOSE,
} from '~/super_sidebar/constants';
import {
  toggleSuperSidebarCollapsed,
  isCollapsed,
} from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { trackContextAccess } from '~/super_sidebar/utils';
import { stubComponent } from 'helpers/stub_component';
import { sidebarData as mockSidebarData, loggedOutSidebarData } from '../mock_data';

const { lg, xl } = breakpoints;
const initialSidebarState = { ...sidebarState };

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager');
jest.mock('~/super_sidebar/utils', () => ({
  ...jest.requireActual('~/super_sidebar/utils'),
  trackContextAccess: jest.fn(),
}));

const trialWidgetStubTestId = 'trial-widget';
const TrialWidgetStub = { template: `<div data-testid="${trialWidgetStubTestId}" />` };
const UserBarStub = {
  template: `<div><a href="#">link</a></div>`,
};

const peekClass = 'super-sidebar-peek';
const hasPeekedClass = 'super-sidebar-has-peeked';
const peekHintClass = 'super-sidebar-peek-hint';

describe('SuperSidebar component', () => {
  let wrapper;

  const findSkipToLink = () => wrapper.findByTestId('super-sidebar-skip-to');
  const findSidebar = () => wrapper.findByTestId('super-sidebar');
  const findUserBar = () => wrapper.findComponent(UserBar);
  const findNavContainer = () => wrapper.findByTestId('nav-container');
  const findHelpCenter = () => wrapper.findComponent(HelpCenter);
  const findSidebarPortalTarget = () => wrapper.findComponent(SidebarPortalTarget);
  const findPeekBehavior = () => wrapper.findComponent(SidebarPeekBehavior);
  const findHoverPeekBehavior = () => wrapper.findComponent(SidebarHoverPeekBehavior);
  const findTrialWidget = () => wrapper.findByTestId(trialWidgetStubTestId);
  const findSidebarMenu = () => wrapper.findComponent(SidebarMenu);
  const findAdminLink = () => wrapper.findByTestId('sidebar-admin-link');
  const findContextHeader = () => wrapper.findComponent('#super-sidebar-context-header');
  let trackingSpy = null;

  const createWrapper = ({
    provide = {},
    sidebarData = mockSidebarData,
    sidebarState: state = {},
  } = {}) => {
    Object.assign(sidebarState, state);

    wrapper = shallowMountExtended(SuperSidebar, {
      provide: {
        showTrialWidget: false,
        ...provide,
      },
      propsData: {
        sidebarData,
      },
      stubs: {
        TrialWidget: TrialWidgetStub,
        UserBar: stubComponent(UserBar, UserBarStub),
      },
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    Object.assign(sidebarState, initialSidebarState);
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('default', () => {
    it('renders skip to main content link when logged in', () => {
      createWrapper();
      expect(findSkipToLink().attributes('href')).toBe('#content-body');
    });

    it('does not render skip to main content link when logged out', () => {
      createWrapper({ sidebarData: { is_logged_in: false } });
      expect(findSkipToLink().exists()).toBe(false);
    });

    it('has accessible role and name', () => {
      createWrapper();
      const nav = wrapper.findByRole('navigation');
      const heading = wrapper.findByText('Primary navigation');
      expect(nav.attributes('aria-labelledby')).toBe('super-sidebar-heading');
      expect(heading.attributes('id')).toBe('super-sidebar-heading');
    });

    it('adds inert attribute when collapsed', () => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      expect(findSidebar().attributes('inert')).toBeDefined();
    });

    it('does not add inert attribute when expanded', () => {
      createWrapper();
      expect(findSidebar().attributes('inert')).toBe(undefined);
    });

    it('renders UserBar with sidebarData', () => {
      createWrapper();
      expect(findUserBar().props('sidebarData')).toBe(mockSidebarData);
    });

    it('renders HelpCenter with sidebarData', () => {
      createWrapper();
      expect(findHelpCenter().props('sidebarData')).toBe(mockSidebarData);
    });

    it('renders extra info section', () => {
      createWrapper();
      expect(wrapper.findComponent(ExtraInfo).exists()).toBe(true);
    });

    it('does not render SidebarMenu when items are empty', () => {
      createWrapper();
      expect(findSidebarMenu().exists()).toBe(false);
    });

    it('renders SidebarMenu with menu items', () => {
      const menuItems = [
        { id: 1, title: 'Menu item 1' },
        { id: 2, title: 'Menu item 2' },
      ];
      createWrapper({ sidebarData: { ...mockSidebarData, current_menu_items: menuItems } });
      expect(findSidebarMenu().props('items')).toBe(menuItems);
    });

    it('renders SidebarPortalTarget', () => {
      createWrapper();
      expect(findSidebarPortalTarget().exists()).toBe(true);
    });

    it('renders hidden shortcut links', () => {
      createWrapper();
      const [linkAttrs] = mockSidebarData.shortcut_links;
      const link = wrapper.find(`.${linkAttrs.css_class}`);

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(linkAttrs.href);
      expect(link.attributes('class')).toContain('gl-hidden');
    });

    it('sets up the sidebar toggle shortcut', () => {
      createWrapper();

      isCollapsed.mockReturnValue(false);
      Mousetrap.trigger('mod+\\');

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledTimes(1);
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(true, true);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_hide', {
        label: 'nav_toggle_keyboard_shortcut',
        property: 'nav_sidebar',
      });

      isCollapsed.mockReturnValue(true);
      Mousetrap.trigger('mod+\\');

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledTimes(2);
      expect(toggleSuperSidebarCollapsed).toHaveBeenCalledWith(false, true);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_show', {
        label: 'nav_toggle_keyboard_shortcut',
        property: 'nav_sidebar',
      });

      jest.spyOn(Mousetrap, 'unbind');

      wrapper.destroy();

      expect(Mousetrap.unbind).toHaveBeenCalledWith(['mod+\\']);
    });

    it('does not render trial widget', () => {
      createWrapper();

      expect(findTrialWidget().exists()).toBe(false);
    });

    it('does not have peek behaviors', () => {
      createWrapper();

      expect(findPeekBehavior().exists()).toBe(false);
      expect(findHoverPeekBehavior().exists()).toBe(false);
    });

    it('renders the context header', () => {
      createWrapper();

      expect(wrapper.text()).toContain('Your work');
    });

    it('does not render a context header if it does not exist', () => {
      createWrapper({ sidebarData: { ...mockSidebarData, current_context_header: null } });

      expect(findContextHeader().exists()).toBe(false);
    });

    describe('item access tracking', () => {
      it('does not track anything if logged out', () => {
        createWrapper({ sidebarData: loggedOutSidebarData });

        expect(trackContextAccess).not.toHaveBeenCalled();
      });

      it('does not track anything if logged in and not within a trackable context', () => {
        createWrapper();

        expect(trackContextAccess).not.toHaveBeenCalled();
      });

      it('tracks item access if logged in within a trackable context', () => {
        const currentContext = { namespace: 'groups' };
        createWrapper({
          sidebarData: {
            ...mockSidebarData,
            current_context: currentContext,
          },
        });

        expect(trackContextAccess).toHaveBeenCalledWith('root', currentContext, '/-/track_visits');
      });
    });
  });

  describe('peek behavior', () => {
    it(`initially makes sidebar inert and peekable (${STATE_CLOSED})`, () => {
      createWrapper({ sidebarState: { isCollapsed: true, isPeekable: true } });

      expect(findSidebar().attributes('inert')).toBeDefined();
      expect(findSidebar().classes()).not.toContain(peekHintClass);
      expect(findSidebar().classes()).not.toContain(hasPeekedClass);
      expect(findSidebar().classes()).not.toContain(peekClass);
    });

    it(`makes sidebar inert and shows peek hint when peek state is ${STATE_WILL_OPEN}`, async () => {
      createWrapper({ sidebarState: { isCollapsed: true, isPeekable: true } });

      findPeekBehavior().vm.$emit('change', STATE_WILL_OPEN);
      await nextTick();

      expect(findSidebar().attributes('inert')).toBeDefined();
      expect(findSidebar().classes()).toContain(peekHintClass);
      expect(findSidebar().classes()).toContain(hasPeekedClass);
      expect(findSidebar().classes()).not.toContain(peekClass);
    });

    it.each([STATE_OPEN, STATE_WILL_CLOSE])(
      'makes sidebar interactive and visible when peek state is %s',
      async (state) => {
        createWrapper({ sidebarState: { isCollapsed: true, isPeekable: true } });

        findPeekBehavior().vm.$emit('change', state);
        await nextTick();

        expect(findSidebar().attributes('inert')).toBe(undefined);
        expect(findSidebar().classes()).toContain(peekClass);
        expect(findSidebar().classes()).not.toContain(peekHintClass);
        expect(findHoverPeekBehavior().exists()).toBe(false);
      },
    );

    it(`makes sidebar interactive and visible when hover peek state is ${STATE_OPEN}`, async () => {
      createWrapper({ sidebarState: { isCollapsed: true, isPeekable: true } });

      findHoverPeekBehavior().vm.$emit('change', STATE_OPEN);
      await nextTick();

      expect(findSidebar().attributes('inert')).toBe(undefined);
      expect(findSidebar().classes()).toContain(peekClass);
      expect(findSidebar().classes()).toContain(hasPeekedClass);
      expect(findSidebar().classes()).not.toContain(peekHintClass);
      expect(findPeekBehavior().exists()).toBe(false);
    });

    it('keeps track of if sidebar has mouseover or not', async () => {
      createWrapper({ sidebarState: { isCollapsed: false, isPeekable: true } });
      expect(findPeekBehavior().props('isMouseOverSidebar')).toBe(false);
      await findSidebar().trigger('mouseenter');
      expect(findPeekBehavior().props('isMouseOverSidebar')).toBe(true);
      await findSidebar().trigger('mouseleave');
      expect(findPeekBehavior().props('isMouseOverSidebar')).toBe(false);
    });
  });

  describe('nav container', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('allows overflow with scroll scrim', () => {
      expect(findNavContainer().element.tagName).toContain('SCROLL-SCRIM');
    });
  });

  describe('when a trial widget is active', () => {
    beforeEach(() => {
      createWrapper({ provide: { showTrialWidget: true } });
    });

    it('renders trial widget', () => {
      expect(findTrialWidget().exists()).toBe(true);
    });
  });

  describe('keyboard interactivity', () => {
    it('does not bind keydown events on screens xl and above', async () => {
      jest.spyOn(document, 'addEventListener');
      jest.spyOn(bp, 'windowWidth').mockReturnValue(xl);
      createWrapper();

      isCollapsed.mockReturnValue(false);
      await nextTick();

      expect(document.addEventListener).not.toHaveBeenCalled();
    });

    it('binds keydown events on screens below xl', () => {
      jest.spyOn(document, 'addEventListener');
      jest.spyOn(bp, 'windowWidth').mockReturnValue(lg);
      createWrapper();

      expect(document.addEventListener).toHaveBeenCalledWith('keydown', wrapper.vm.focusTrap);
    });
  });

  describe('link to Admin area', () => {
    describe('when user is admin', () => {
      it('renders', () => {
        createWrapper({
          sidebarData: {
            ...mockSidebarData,
            is_admin: true,
          },
        });
        expect(findAdminLink().attributes('href')).toBe(mockSidebarData.admin_url);
      });
    });

    describe('when user is not admin', () => {
      it('renders', () => {
        createWrapper();
        expect(findAdminLink().exists()).toBe(false);
      });
    });
  });

  describe('focusing first focusable element', () => {
    const findFirstFocusableElement = () => findUserBar().find('a');
    let focusSpy;

    beforeEach(() => {
      createWrapper({ sidebarState: { isCollapsed: true, isPeekable: true } });
      focusSpy = jest.spyOn(findFirstFocusableElement().element, 'focus');
    });

    it('focuses the first focusable element when sidebar is not peeking', async () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(lg);

      wrapper.vm.sidebarState.isCollapsed = false;
      await nextTick();
      await nextTick();

      expect(focusSpy).toHaveBeenCalledTimes(1);
    });

    it("doesn't focus the first focusable element when sidebar is peeking", async () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(lg);

      findHoverPeekBehavior().vm.$emit('change', STATE_OPEN);
      await nextTick();

      expect(focusSpy).not.toHaveBeenCalled();
    });

    it("doesn't focus the first focusable element when sidebar is collapsed", async () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(lg);

      wrapper.vm.sidebarState.isCollapsed = false;
      await nextTick();
      await nextTick();

      expect(focusSpy).toHaveBeenCalledTimes(1);

      wrapper.vm.sidebarState.isCollapsed = true;
      await nextTick();

      expect(focusSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('pressing ESC key', () => {
    beforeEach(() => {
      createWrapper({ sidebarState: { isCollapsed: false, isPeekable: true } });
    });

    const ESC_KEY = 27;
    it('collapses sidebar when sidebar is in overlay mode', async () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(lg);
      await findSidebar().trigger('keydown.esc', { keyCode: ESC_KEY });

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalled();
    });

    it('does nothing when sidebar is in peek mode', () => {
      findHoverPeekBehavior().vm.$emit('change', STATE_OPEN);

      findSidebar().trigger('keydown', { keyCode: ESC_KEY });
      expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();
    });

    it('does nothing when sidebar is not overlapping', () => {
      jest.spyOn(bp, 'windowWidth').mockReturnValue(xl);

      findSidebar().trigger('keydown', { keyCode: ESC_KEY });
      expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();
    });
  });
});
