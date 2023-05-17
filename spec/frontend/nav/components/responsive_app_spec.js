import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ResponsiveApp from '~/nav/components/responsive_app.vue';
import ResponsiveHeader from '~/nav/components/responsive_header.vue';
import ResponsiveHome from '~/nav/components/responsive_home.vue';
import TopNavContainerView from '~/nav/components/top_nav_container_view.vue';
import { resetMenuItemsActive } from '~/nav/utils/reset_menu_items_active';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';
import { TEST_NAV_DATA } from '../mock_data';

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
  const findHome = () => wrapper.findComponent(ResponsiveHome);
  const findMobileOverlay = () => wrapper.find('[data-testid="mobile-overlay"]');
  const findSubviewHeader = () => wrapper.findComponent(ResponsiveHeader);
  const findSubviewContainer = () => wrapper.findComponent(TopNavContainerView);
  const hasMobileOverlayVisible = () => findMobileOverlay().classes('mobile-nav-open');

  beforeEach(() => {
    document.body.innerHTML = '';
    // Add test class to reset state + assert that we're adding classes correctly
    document.body.className = 'test-class';
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

          await nextTick();
        }, Promise.resolve());

        expect(hasMobileOverlayVisible()).toBe(expectation);
      },
    );
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

      await nextTick();
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
});
