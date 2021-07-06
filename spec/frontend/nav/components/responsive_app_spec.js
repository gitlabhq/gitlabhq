import { shallowMount } from '@vue/test-utils';
import ResponsiveApp from '~/nav/components/responsive_app.vue';
import ResponsiveHeader from '~/nav/components/responsive_header.vue';
import ResponsiveHome from '~/nav/components/responsive_home.vue';
import TopNavContainerView from '~/nav/components/top_nav_container_view.vue';
import eventHub, { EVENT_RESPONSIVE_TOGGLE } from '~/nav/event_hub';
import { resetMenuItemsActive } from '~/nav/utils/reset_menu_items_active';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import { TEST_NAV_DATA } from '../mock_data';

const HTML_HEADER_CONTENT = '<div class="header-content"></div>';
const HTML_MENU_EXPANDED = '<div class="menu-expanded"></div>';
const HTML_HEADER_WITH_MENU_EXPANDED =
  '<div></div><div class="header-content menu-expanded"></div>';

describe('~/nav/components/responsive_app.vue', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ResponsiveApp, {
      propsData: {
        navData: TEST_NAV_DATA,
      },
      stubs: {
        KeepAliveSlots,
      },
    });
  };
  const triggerResponsiveToggle = () => eventHub.$emit(EVENT_RESPONSIVE_TOGGLE);

  const findHome = () => wrapper.findComponent(ResponsiveHome);
  const findMobileOverlay = () => wrapper.find('[data-testid="mobile-overlay"]');
  const findSubviewHeader = () => wrapper.findComponent(ResponsiveHeader);
  const findSubviewContainer = () => wrapper.findComponent(TopNavContainerView);
  const hasBodyResponsiveOpen = () => document.body.classList.contains('top-nav-responsive-open');
  const hasMobileOverlayVisible = () => findMobileOverlay().classes('mobile-nav-open');

  beforeEach(() => {
    document.body.innerHTML = '';
    // Add test class to reset state + assert that we're adding classes correctly
    document.body.className = 'test-class';
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows home by default', () => {
      expect(findHome().isVisible()).toBe(true);
      expect(findHome().props()).toEqual({
        navData: resetMenuItemsActive(TEST_NAV_DATA),
      });
    });

    it.each`
      bodyHtml                          | expectation
      ${''}                             | ${false}
      ${HTML_HEADER_CONTENT}            | ${false}
      ${HTML_MENU_EXPANDED}             | ${false}
      ${HTML_HEADER_WITH_MENU_EXPANDED} | ${true}
    `(
      'with responsive toggle event and html set to $bodyHtml, responsive open = $expectation',
      ({ bodyHtml, expectation }) => {
        document.body.innerHTML = bodyHtml;

        triggerResponsiveToggle();

        expect(hasBodyResponsiveOpen()).toBe(expectation);
      },
    );

    it.each`
      events                                          | expectation
      ${[]}                                           | ${false}
      ${['bv::dropdown::show']}                       | ${true}
      ${['bv::dropdown::show', 'bv::dropdown::hide']} | ${false}
    `(
      'with root events $events, movile overlay visible = $expectation',
      async ({ events, expectation }) => {
        // `await...reduce(async` is like doing an `forEach(async (...))` excpet it works
        await events.reduce(async (acc, evt) => {
          await acc;

          wrapper.vm.$root.$emit(evt);

          await wrapper.vm.$nextTick();
        }, Promise.resolve());

        expect(hasMobileOverlayVisible()).toBe(expectation);
      },
    );
  });

  describe('with menu expanded in body', () => {
    beforeEach(() => {
      document.body.innerHTML = HTML_HEADER_WITH_MENU_EXPANDED;
      createComponent();
    });

    it('sets the body responsive open', () => {
      expect(hasBodyResponsiveOpen()).toBe(true);
    });
  });

  const projectsContainerProps = {
    containerClass: 'gl-px-3',
    frequentItemsDropdownType: ResponsiveApp.FREQUENT_ITEMS_PROJECTS.namespace,
    frequentItemsVuexModule: ResponsiveApp.FREQUENT_ITEMS_PROJECTS.vuexModule,
    currentItem: {},
    linksPrimary: TEST_NAV_DATA.views.projects.linksPrimary,
    linksSecondary: TEST_NAV_DATA.views.projects.linksSecondary,
  };
  const groupsContainerProps = {
    containerClass: 'gl-px-3',
    frequentItemsDropdownType: ResponsiveApp.FREQUENT_ITEMS_GROUPS.namespace,
    frequentItemsVuexModule: ResponsiveApp.FREQUENT_ITEMS_GROUPS.vuexModule,
    currentItem: {},
    linksPrimary: TEST_NAV_DATA.views.groups.linksPrimary,
    linksSecondary: TEST_NAV_DATA.views.groups.linksSecondary,
  };

  describe.each`
    view          | header        | containerProps
    ${'projects'} | ${'Projects'} | ${projectsContainerProps}
    ${'groups'}   | ${'Groups'}   | ${groupsContainerProps}
  `('when menu item with $view is clicked', ({ view, header, containerProps }) => {
    beforeEach(async () => {
      createComponent();

      findHome().vm.$emit('menu-item-click', { view });

      await wrapper.vm.$nextTick();
    });

    it('shows header', () => {
      expect(findSubviewHeader().text()).toBe(header);
    });

    it('shows container subview', () => {
      expect(findSubviewContainer().props()).toEqual(containerProps);
    });

    it('hides home', () => {
      expect(findHome().isVisible()).toBe(false);
    });

    describe('when header back button is clicked', () => {
      beforeEach(() => {
        findSubviewHeader().vm.$emit('menu-item-click', { view: 'home' });
      });

      it('shows home', () => {
        expect(findHome().isVisible()).toBe(true);
      });
    });
  });

  describe('when destroyed', () => {
    beforeEach(() => {
      createComponent();
      wrapper.destroy();
    });

    it('responsive toggle event does nothing', () => {
      triggerResponsiveToggle();

      expect(hasBodyResponsiveOpen()).toBe(false);
    });
  });
});
