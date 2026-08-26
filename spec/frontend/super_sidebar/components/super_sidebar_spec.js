import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-syntax -- test mocks viewport breakpoints used by the source component
import { GlBreakpointInstance, breakpoints } from '@gitlab/ui/src/utils';
import { PortalTarget } from 'portal-vue';
import { Mousetrap } from '~/lib/mousetrap';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import superSidebarDataQuery from '~/super_sidebar/graphql/queries/super_sidebar.query.graphql';
import SuperSidebar from '~/super_sidebar/components/super_sidebar.vue';
import HelpCenter from '~/super_sidebar/components/help_center.vue';
import SidebarPortalTarget from '~/super_sidebar/components/sidebar_portal_target.vue';
import SidebarMenu from '~/super_sidebar/components/sidebar_menu.vue';
import MenuSection from '~/super_sidebar/components/menu_section.vue';
import IconOnlyToggle from '~/super_sidebar/components/icon_only_toggle.vue';
import ManageOrganizationButton from '~/super_sidebar/components/manage_organization_button.vue';
import { sidebarState } from '~/super_sidebar/state';
import {
  toggleSuperSidebarCollapsed,
  toggleSuperSidebarIconOnly,
  isCollapsed,
} from '~/super_sidebar/super_sidebar_collapsed_state_manager';
import { trackContextAccess } from '~/super_sidebar/utils';
import { stubComponent } from 'helpers/stub_component';
import { sidebarData as mockSidebarData, loggedOutSidebarData } from '../mock_data';

Vue.use(VueApollo);

const { lg, xl } = breakpoints;
const initialSidebarState = { ...sidebarState };

jest.mock('~/super_sidebar/super_sidebar_collapsed_state_manager');
jest.mock('~/super_sidebar/utils', () => ({
  ...jest.requireActual('~/super_sidebar/utils'),
  trackContextAccess: jest.fn(),
}));

const trialWidgetStubTestId = 'trial-widget';
const TrialWidgetStub = { template: `<div data-testid="${trialWidgetStubTestId}" />` };
const SidebarMenuStub = {
  template: `<div><a href="#">link</a></div>`,
};

describe('SuperSidebar component', () => {
  let wrapper;

  const findSidebar = () => wrapper.findByTestId('super-sidebar');
  const findNavContainer = () => wrapper.findByTestId('nav-container');
  const findHelpCenter = () => wrapper.findComponent(HelpCenter);
  const findSidebarPortalTarget = () => wrapper.findComponent(SidebarPortalTarget);
  const findSettingsDisclosureTarget = () =>
    wrapper
      .findAllComponents(PortalTarget)
      .wrappers.find((w) => w.props('name') === 'super-sidebar-settings-disclosure');
  const findTrialWidget = () => wrapper.findByTestId(trialWidgetStubTestId);
  const findIconOnlyToggle = () => wrapper.findComponent(IconOnlyToggle);
  const findManageOrganizationButton = () => wrapper.findComponent(ManageOrganizationButton);
  const findSidebarMenu = () => wrapper.findComponent(SidebarMenu);
  const findContextHeader = () => wrapper.find('#super-sidebar-context-header');

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
        SidebarMenu: stubComponent(SidebarMenu, SidebarMenuStub),
      },
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    Object.assign(sidebarState, initialSidebarState);
  });

  describe('default', () => {
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

    it('renders HelpCenter with sidebarData', () => {
      createWrapper();
      expect(findHelpCenter().props('sidebarData')).toBe(mockSidebarData);
    });

    it('does not render SidebarMenu when items are empty', () => {
      createWrapper({ sidebarData: { ...mockSidebarData, current_menu_items: [] } });
      expect(findSidebarMenu().exists()).toBe(false);
    });

    it('renders SidebarMenu with menu items', () => {
      createWrapper();
      expect(findSidebarMenu().props('items')).toBe(mockSidebarData.current_menu_items);
    });

    it('renders SidebarPortalTarget', () => {
      createWrapper();
      expect(findSidebarPortalTarget().exists()).toBe(true);
    });

    describe('settings disclosure portal target', () => {
      it('is not rendered when hideUnpinnedSidebarItems is disabled', () => {
        createWrapper();
        expect(findSettingsDisclosureTarget()).toBeUndefined();
      });

      it('is rendered when hideUnpinnedSidebarItems is enabled', () => {
        createWrapper({ provide: { glFeatures: { hideUnpinnedSidebarItems: true } } });
        expect(findSettingsDisclosureTarget()).not.toBeUndefined();
      });
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

      Mousetrap.trigger('mod+\\');

      expect(toggleSuperSidebarIconOnly).toHaveBeenCalledTimes(1);

      Mousetrap.trigger('mod+\\');

      expect(toggleSuperSidebarIconOnly).toHaveBeenCalledTimes(2);

      jest.spyOn(Mousetrap, 'unbind');

      wrapper.destroy();

      expect(Mousetrap.unbind).toHaveBeenCalledWith(['mod+\\']);
    });

    it('does not render trial widget', () => {
      createWrapper();

      expect(findTrialWidget().exists()).toBe(false);
    });

    it('renders icon-only toggle', () => {
      createWrapper();
      expect(findIconOnlyToggle().exists()).toBe(true);
    });

    it('does not render the manage organization button without a link', () => {
      createWrapper();
      expect(findManageOrganizationButton().exists()).toBe(false);
    });

    it('renders the manage organization button when a link is present', () => {
      const manageOrganizationLink = '/o/my-org/admin';
      createWrapper({
        sidebarData: { ...mockSidebarData, manage_organization_link: manageOrganizationLink },
      });

      expect(findManageOrganizationButton().exists()).toBe(true);
      expect(findManageOrganizationButton().props('href')).toBe(manageOrganizationLink);
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

        expect(trackContextAccess).toHaveBeenCalledWith('root', currentContext);
      });
    });
  });

  describe('in the panel-based layout', () => {
    describe('on desktop', () => {
      describe('in icon-only mode', () => {
        beforeEach(() => {
          createWrapper({
            provide: {
              showTrialWidget: true,
            },
            sidebarState: { isMobile: false, isIconOnly: true },
          });
        });

        it('renders the icon-only toggle', () => {
          expect(findIconOnlyToggle().exists()).toBe(true);
        });

        it('does not render the context header text', () => {
          expect(findContextHeader().exists()).toBe(false);
        });

        it('does not render the any widgets', () => {
          expect(findTrialWidget().exists()).toBe(false);
        });
      });

      describe('in full mode', () => {
        beforeEach(() => {
          createWrapper({
            provide: {
              showTrialWidget: true,
            },
            sidebarState: { isMobile: false, isIconOnly: false },
          });
        });

        it('renders the context header normally', () => {
          expect(findContextHeader().text()).toBe('Your work');
        });

        it('renders the widgets', () => {
          expect(findTrialWidget().exists()).toBe(true);
        });
      });
    });

    describe('on mobile', () => {
      beforeEach(() => {
        createWrapper({
          sidebarState: { isMobile: true },
        });
      });

      it('does not render the icon-only toggle', () => {
        expect(findIconOnlyToggle().exists()).toBe(false);
      });

      it('sets the correct class', () => {
        expect(findSidebar().classes()).toContain('super-sidebar-is-mobile');
      });
    });

    describe('when toggling between modes', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does not have the `.super-sidebar-toggled-manually` class by default', () => {
        expect(findSidebar().classes()).not.toContain('super-sidebar-toggled-manually');
      });

      it('adds the `.super-sidebar-toggled-manually` class when the sidebar mode is toggled', async () => {
        findIconOnlyToggle().vm.$emit('toggle');
        await nextTick();

        expect(findSidebar().classes()).toContain('super-sidebar-toggled-manually');
      });

      it('removes the `.super-sidebar-toggled-manually` class once the sidebar mode has transitioned', async () => {
        findIconOnlyToggle().vm.$emit('toggle');
        await nextTick();
        findSidebar().trigger('transitionend');
        await nextTick();

        expect(findSidebar().classes()).not.toContain('super-sidebar-toggled-manually');
      });
    });

    it('does not render when items are empty', () => {
      createWrapper({
        sidebarData: { ...mockSidebarData, current_menu_items: [] },
      });
      expect(findSidebar().exists()).toBe(false);
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
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);
      createWrapper();

      isCollapsed.mockReturnValue(false);
      await nextTick();

      expect(document.addEventListener).not.toHaveBeenCalled();
    });

    it('binds keydown events on screens below xl', () => {
      jest.spyOn(document, 'addEventListener');
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(lg);
      createWrapper();

      expect(document.addEventListener).toHaveBeenCalledWith('keydown', wrapper.vm.focusTrap);
    });
  });

  describe('focusing first focusable element', () => {
    const findFirstFocusableElement = () => findSidebarMenu().find('a');
    let focusSpy;

    beforeEach(() => {
      createWrapper({ sidebarState: { isCollapsed: true } });
      focusSpy = jest.spyOn(findFirstFocusableElement().element, 'focus');
    });

    it('focuses the first focusable element', async () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(lg);

      wrapper.vm.sidebarState.isCollapsed = false;
      await nextTick();
      await nextTick();

      expect(focusSpy).toHaveBeenCalledTimes(1);
    });

    it("doesn't focus the first focusable element when sidebar is collapsed", async () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(lg);

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
      createWrapper({ sidebarState: { isCollapsed: false } });
    });

    const ESC_KEY = 27;
    it('collapses sidebar when sidebar is in overlay mode', async () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(lg);
      await findSidebar().trigger('keydown.esc', { keyCode: ESC_KEY });

      expect(toggleSuperSidebarCollapsed).toHaveBeenCalled();
    });

    it('does nothing when sidebar is not overlapping', () => {
      jest.spyOn(GlBreakpointInstance, 'windowWidth').mockReturnValue(xl);

      findSidebar().trigger('keydown', { keyCode: ESC_KEY });
      expect(toggleSuperSidebarCollapsed).not.toHaveBeenCalled();
    });
  });

  describe('portalled settings disclosure', () => {
    // The Settings section is portalled out of SidebarMenu into the sidebar
    // footer. Icon-only state still reaches it through inject only because
    // SuperSidebar both provides it and renders the portal target. This would
    // break silently if the target ever moved out of SuperSidebar, so mount the
    // real SidebarMenu (not the stub) to exercise the whole chain.
    const sidebarDataWithSettings = {
      ...mockSidebarData,
      panel_type: 'project',
      is_logged_in: true,
      current_menu_items: [
        {
          id: 'settings_menu',
          title: 'Settings',
          icon: 'settings',
          items: [{ id: 'settings_general', title: 'General', link: '/general' }],
        },
      ],
    };

    const mountWithSettings = async ({ isIconOnly }) => {
      Object.assign(sidebarState, { isMobile: false, isIconOnly });

      wrapper = mountExtended(SuperSidebar, {
        apolloProvider: createMockApollo([
          [superSidebarDataQuery, jest.fn().mockResolvedValue({ data: { project: null } })],
        ]),
        propsData: { sidebarData: sidebarDataWithSettings },
        provide: {
          showTrialWidget: false,
          currentPath: 'group/project',
          glFeatures: { hideUnpinnedSidebarItems: true },
        },
        stubs: {
          UserBar: true,
          HelpCenter: true,
          SidebarPortalTarget: true,
          IconOnlyToggle: true,
          TrialWidget: true,
          PinnedSection: true,
          NavItem: true,
          FeatureLibraryModal: true,
        },
        attachTo: document.body,
      });

      // Portal content only reaches the target on the next tick.
      await nextTick();
    };

    const findPortalledSettingsSection = () =>
      findSettingsDisclosureTarget()
        .findAllComponents(MenuSection)
        .wrappers.find((w) => w.props('item').id === 'settings_menu');

    it.each([true, false])(
      'passes injected isIconOnly=%s to the portalled settings section',
      async (isIconOnly) => {
        await mountWithSettings({ isIconOnly });

        expect(findPortalledSettingsSection().vm.isIconOnly).toBe(isIconOnly);
      },
    );
  });
});
