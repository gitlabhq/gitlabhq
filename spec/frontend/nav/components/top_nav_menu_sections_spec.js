import { shallowMount } from '@vue/test-utils';
import TopNavMenuSections from '~/nav/components/top_nav_menu_sections.vue';

const TEST_SECTIONS = [
  {
    id: 'primary',
    menuItems: [{ id: 'test', href: '/test/href' }, { id: 'foo' }, { id: 'bar' }],
  },
  {
    id: 'secondary',
    menuItems: [{ id: 'lorem' }, { id: 'ipsum' }],
  },
];

describe('~/nav/components/top_nav_menu_sections.vue', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TopNavMenuSections, {
      propsData: {
        sections: TEST_SECTIONS,
        ...props,
      },
    });
  };

  const findMenuItemModels = (parent) =>
    parent.findAll('[data-testid="menu-item"]').wrappers.map((x) => ({
      menuItem: x.props('menuItem'),
      classes: x.classes(),
    }));
  const findSectionModels = () =>
    wrapper.findAll('[data-testid="menu-section"]').wrappers.map((x) => ({
      classes: x.classes(),
      menuItems: findMenuItemModels(x),
    }));

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders sections with menu items', () => {
      expect(findSectionModels()).toEqual([
        {
          classes: [],
          menuItems: [
            {
              menuItem: TEST_SECTIONS[0].menuItems[0],
              classes: ['gl-w-full'],
            },
            ...TEST_SECTIONS[0].menuItems.slice(1).map((menuItem) => ({
              menuItem,
              classes: ['gl-w-full', 'gl-mt-1'],
            })),
          ],
        },
        {
          classes: [...TopNavMenuSections.BORDER_CLASSES.split(' '), 'gl-mt-3'],
          menuItems: [
            {
              menuItem: TEST_SECTIONS[1].menuItems[0],
              classes: ['gl-w-full'],
            },
            ...TEST_SECTIONS[1].menuItems.slice(1).map((menuItem) => ({
              menuItem,
              classes: ['gl-w-full', 'gl-mt-1'],
            })),
          ],
        },
      ]);
    });

    it('when clicked menu item with href, does nothing', () => {
      const menuItem = wrapper.findAll('[data-testid="menu-item"]').at(0);

      menuItem.vm.$emit('click');

      expect(wrapper.emitted()).toEqual({});
    });

    it('when clicked menu item without href, emits "menu-item-click"', () => {
      const menuItem = wrapper.findAll('[data-testid="menu-item"]').at(1);

      menuItem.vm.$emit('click');

      expect(wrapper.emitted('menu-item-click')).toEqual([[TEST_SECTIONS[0].menuItems[1]]]);
    });
  });

  describe('with withTopBorder=true', () => {
    beforeEach(() => {
      createComponent({ withTopBorder: true });
    });

    it('renders border classes for top section', () => {
      expect(findSectionModels().map((x) => x.classes)).toEqual([
        [...TopNavMenuSections.BORDER_CLASSES.split(' ')],
        [...TopNavMenuSections.BORDER_CLASSES.split(' '), 'gl-mt-3'],
      ]);
    });
  });
});
