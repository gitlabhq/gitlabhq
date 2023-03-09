import { shallowMount } from '@vue/test-utils';
import TopNavMenuSections from '~/nav/components/top_nav_menu_sections.vue';

const TEST_SECTIONS = [
  {
    id: 'primary',
    menuItems: [
      { type: 'header', title: 'Heading' },
      { type: 'item', id: 'test', href: '/test/href' },
      { type: 'header', title: 'Another Heading' },
      { type: 'item', id: 'foo' },
      { type: 'item', id: 'bar' },
    ],
  },
  {
    id: 'secondary',
    menuItems: [
      { type: 'item', id: 'lorem' },
      { type: 'item', id: 'ipsum' },
    ],
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
    parent.findAll('[data-testid="menu-header"],[data-testid="menu-item"]').wrappers.map((x) => {
      return {
        menuItem: x.vm
          ? {
              type: 'item',
              ...x.props('menuItem'),
            }
          : {
              type: 'header',
              title: x.text(),
            },
        classes: x.classes(),
      };
    });
  const findSectionModels = () =>
    wrapper.findAll('[data-testid="menu-section"]').wrappers.map((x) => ({
      classes: x.classes(),
      menuItems: findMenuItemModels(x),
    }));

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders sections with menu items', () => {
      const headerClasses = ['gl-px-4', 'gl-py-2', 'gl-text-gray-900', 'gl-display-block'];
      const itemClasses = ['gl-w-full'];

      expect(findSectionModels()).toEqual([
        {
          classes: [],
          menuItems: TEST_SECTIONS[0].menuItems.map((menuItem, index) => {
            const classes = menuItem.type === 'header' ? [...headerClasses] : [...itemClasses];
            if (index > 0) classes.push(menuItem.type === 'header' ? 'gl-pt-3!' : 'gl-mt-1');
            return {
              menuItem,
              classes,
            };
          }),
        },
        {
          classes: [
            ...TopNavMenuSections.BORDER_CLASSES.split(' '),
            'gl-border-gray-50',
            'gl-mt-3',
          ],
          menuItems: TEST_SECTIONS[1].menuItems.map((menuItem, index) => {
            const classes = menuItem.type === 'header' ? [...headerClasses] : [...itemClasses];
            if (index > 0) classes.push(menuItem.type === 'header' ? 'gl-pt-3!' : 'gl-mt-1');
            return {
              menuItem,
              classes,
            };
          }),
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

      expect(wrapper.emitted('menu-item-click')).toEqual([[TEST_SECTIONS[0].menuItems[3]]]);
    });
  });

  describe('with withTopBorder=true', () => {
    beforeEach(() => {
      createComponent({ withTopBorder: true });
    });

    it('renders border classes for top section', () => {
      expect(findSectionModels().map((x) => x.classes)).toEqual([
        [...TopNavMenuSections.BORDER_CLASSES.split(' '), 'gl-border-gray-50'],
        [...TopNavMenuSections.BORDER_CLASSES.split(' '), 'gl-border-gray-50', 'gl-mt-3'],
      ]);
    });
  });

  describe('with isPrimarySection=true', () => {
    beforeEach(() => {
      createComponent({ isPrimarySection: true });
    });

    it('renders border classes for top section', () => {
      expect(findSectionModels().map((x) => x.classes)).toEqual([
        [],
        [...TopNavMenuSections.BORDER_CLASSES.split(' '), 'gl-border-gray-100', 'gl-mt-3'],
      ]);
    });
  });
});
