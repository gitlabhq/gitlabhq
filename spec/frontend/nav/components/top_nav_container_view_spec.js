import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import FrequentItemsApp from '~/frequent_items/components/app.vue';
import { FREQUENT_ITEMS_PROJECTS } from '~/frequent_items/constants';
import eventHub from '~/frequent_items/event_hub';
import TopNavContainerView from '~/nav/components/top_nav_container_view.vue';
import TopNavMenuSections from '~/nav/components/top_nav_menu_sections.vue';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';
import { TEST_NAV_DATA } from '../mock_data';

const DEFAULT_PROPS = {
  frequentItemsDropdownType: FREQUENT_ITEMS_PROJECTS.namespace,
  frequentItemsVuexModule: FREQUENT_ITEMS_PROJECTS.vuexModule,
  linksPrimary: TEST_NAV_DATA.primary,
  linksSecondary: TEST_NAV_DATA.secondary,
  containerClass: 'test-frequent-items-container-class',
};
const TEST_OTHER_PROPS = {
  namespace: 'projects',
  currentUserName: 'test-user',
  currentItem: { id: 'test' },
};

describe('~/nav/components/top_nav_container_view.vue', () => {
  let wrapper;

  const createComponent = (props = {}, options = {}) => {
    wrapper = shallowMount(TopNavContainerView, {
      propsData: {
        ...DEFAULT_PROPS,
        ...TEST_OTHER_PROPS,
        ...props,
      },
      ...options,
    });
  };

  const findMenuSections = () => wrapper.findComponent(TopNavMenuSections);
  const findFrequentItemsApp = () => {
    const parent = wrapper.findComponent(VuexModuleProvider);

    return {
      vuexModule: parent.props('vuexModule'),
      props: parent.findComponent(FrequentItemsApp).props(),
      attributes: parent.findComponent(FrequentItemsApp).attributes(),
    };
  };
  const findFrequentItemsContainer = () => wrapper.find('[data-testid="frequent-items-container"]');

  afterEach(() => {
    wrapper.destroy();
  });

  it.each(['projects', 'groups'])(
    'emits frequent items event to event hub (%s)',
    async (frequentItemsDropdownType) => {
      const listener = jest.fn();
      eventHub.$on(`${frequentItemsDropdownType}-dropdownOpen`, listener);
      createComponent({ frequentItemsDropdownType });

      expect(listener).not.toHaveBeenCalled();

      await nextTick();

      expect(listener).toHaveBeenCalled();
    },
  );

  describe('default', () => {
    const EXTRA_ATTRS = { 'data-test-attribute': 'foo' };

    beforeEach(() => {
      createComponent({}, { attrs: EXTRA_ATTRS });
    });

    it('does not inherit extra attrs', () => {
      expect(wrapper.attributes()).toEqual({
        class: expect.any(String),
      });
    });

    it('renders frequent items app', () => {
      expect(findFrequentItemsApp()).toEqual({
        vuexModule: DEFAULT_PROPS.frequentItemsVuexModule,
        props: expect.objectContaining(
          merge({ currentItem: { lastAccessedOn: Date.now() } }, TEST_OTHER_PROPS),
        ),
        attributes: expect.objectContaining(EXTRA_ATTRS),
      });
    });

    it('renders given container class', () => {
      expect(findFrequentItemsContainer().classes(DEFAULT_PROPS.containerClass)).toBe(true);
    });

    it('renders menu sections', () => {
      const sections = [
        { id: 'primary', menuItems: TEST_NAV_DATA.primary },
        { id: 'secondary', menuItems: TEST_NAV_DATA.secondary },
      ];

      expect(findMenuSections().props()).toEqual({
        sections,
        withTopBorder: true,
      });
    });
  });

  describe('without secondary links', () => {
    beforeEach(() => {
      createComponent({
        linksSecondary: [],
      });
    });

    it('renders one menu item group', () => {
      expect(findMenuSections().props('sections')).toEqual([
        { id: 'primary', menuItems: TEST_NAV_DATA.primary },
      ]);
    });
  });
});
