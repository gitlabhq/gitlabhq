import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TopNavMenuItem from '~/nav/components/top_nav_menu_item.vue';

const TEST_MENU_ITEM = {
  title: 'Cheeseburger',
  icon: 'search',
  href: '/pretty/good/burger',
  view: 'burger-view',
};

describe('~/nav/components/top_nav_menu_item.vue', () => {
  let listener;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TopNavMenuItem, {
      propsData: {
        menuItem: TEST_MENU_ITEM,
        ...props,
      },
      listeners: {
        click: listener,
      },
    });
  };

  const findButton = () => wrapper.find(GlButton);
  const findButtonIcons = () =>
    findButton()
      .findAllComponents(GlIcon)
      .wrappers.map((x) => x.props('name'));

  beforeEach(() => {
    listener = jest.fn();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders button href and text', () => {
      const button = findButton();

      expect(button.attributes('href')).toBe(TEST_MENU_ITEM.href);
      expect(button.text()).toBe(TEST_MENU_ITEM.title);
    });

    it('passes listeners to button', () => {
      expect(listener).not.toHaveBeenCalled();

      findButton().vm.$emit('click', 'TEST');

      expect(listener).toHaveBeenCalledWith('TEST');
    });
  });

  describe.each`
    desc                      | menuItem                                         | expectedIcons
    ${'default'}              | ${TEST_MENU_ITEM}                                | ${[TEST_MENU_ITEM.icon, 'chevron-right']}
    ${'with no icon'}         | ${{ ...TEST_MENU_ITEM, icon: null }}             | ${['chevron-right']}
    ${'with no view'}         | ${{ ...TEST_MENU_ITEM, view: null }}             | ${[TEST_MENU_ITEM.icon]}
    ${'with no icon or view'} | ${{ ...TEST_MENU_ITEM, view: null, icon: null }} | ${[]}
  `('$desc', ({ menuItem, expectedIcons }) => {
    beforeEach(() => {
      createComponent({ menuItem });
    });

    it(`renders expected icons ${JSON.stringify(expectedIcons)}`, () => {
      expect(findButtonIcons()).toEqual(expectedIcons);
    });
  });
});
