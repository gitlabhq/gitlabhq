import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TopNavMenuItem from '~/nav/components/top_nav_menu_item.vue';

const TEST_MENU_ITEM = {
  title: 'Cheeseburger',
  icon: 'search',
  href: '/pretty/good/burger',
  view: 'burger-view',
  data: { qa_selector: 'not-a-real-selector', method: 'post', testFoo: 'test' },
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
      .wrappers.map((x) => ({
        name: x.props('name'),
        classes: x.classes(),
      }));

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

    it('renders button data attributes', () => {
      const button = findButton();

      expect(button.attributes()).toMatchObject({
        'data-qa-selector': TEST_MENU_ITEM.data.qa_selector,
        'data-method': TEST_MENU_ITEM.data.method,
        'data-test-foo': TEST_MENU_ITEM.data.testFoo,
      });
    });

    it('passes listeners to button', () => {
      expect(listener).not.toHaveBeenCalled();

      findButton().vm.$emit('click', 'TEST');

      expect(listener).toHaveBeenCalledWith('TEST');
    });

    it('renders expected icons', () => {
      expect(findButtonIcons()).toEqual([
        {
          name: TEST_MENU_ITEM.icon,
          classes: ['gl-mr-3!'],
        },
        {
          name: 'chevron-right',
          classes: ['gl-ml-auto'],
        },
      ]);
    });
  });

  describe('with icon-only', () => {
    beforeEach(() => {
      createComponent({ iconOnly: true });
    });

    it('does not render title or view icon', () => {
      expect(wrapper.text()).toBe('');
    });

    it('only renders menuItem icon', () => {
      expect(findButtonIcons()).toEqual([
        {
          name: TEST_MENU_ITEM.icon,
          classes: [],
        },
      ]);
    });
  });

  describe.each`
    desc                      | menuItem                                         | expectedIcons
    ${'with no icon'}         | ${{ ...TEST_MENU_ITEM, icon: null }}             | ${['chevron-right']}
    ${'with no view'}         | ${{ ...TEST_MENU_ITEM, view: null }}             | ${[TEST_MENU_ITEM.icon]}
    ${'with no icon or view'} | ${{ ...TEST_MENU_ITEM, view: null, icon: null }} | ${[]}
  `('$desc', ({ menuItem, expectedIcons }) => {
    beforeEach(() => {
      createComponent({ menuItem });
    });

    it(`renders expected icons ${JSON.stringify(expectedIcons)}`, () => {
      expect(findButtonIcons().map((x) => x.name)).toEqual(expectedIcons);
    });
  });

  describe.each`
    desc                         | active   | cssClass                        | expectedClasses
    ${'default'}                 | ${false} | ${''}                           | ${[]}
    ${'with css class'}          | ${false} | ${'test-css-class testing-123'} | ${['test-css-class', 'testing-123']}
    ${'with css class & active'} | ${true}  | ${'test-css-class'}             | ${['test-css-class', ...TopNavMenuItem.ACTIVE_CLASS.split(' ')]}
  `('$desc', ({ active, cssClass, expectedClasses }) => {
    beforeEach(() => {
      createComponent({
        menuItem: {
          ...TEST_MENU_ITEM,
          active,
          css_class: cssClass,
        },
      });
    });

    it('renders expected classes', () => {
      expect(wrapper.classes()).toStrictEqual([
        'top-nav-menu-item',
        'gl-display-block',
        ...expectedClasses,
      ]);
    });
  });
});
