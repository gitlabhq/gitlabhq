import { GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TopNavNewDropdown from '~/nav/components/top_nav_new_dropdown.vue';

const TEST_VIEW_MODEL = {
  title: 'Dropdown',
  menu_sections: [
    {
      title: 'Section 1',
      menu_items: [
        { id: 'foo-1', title: 'Foo 1', href: '/foo/1' },
        { id: 'foo-2', title: 'Foo 2', href: '/foo/2' },
        { id: 'foo-3', title: 'Foo 3', href: '/foo/3' },
      ],
    },
    {
      title: 'Section 2',
      menu_items: [
        { id: 'bar-1', title: 'Bar 1', href: '/bar/1' },
        { id: 'bar-2', title: 'Bar 2', href: '/bar/2' },
      ],
    },
  ],
};

describe('~/nav/components/top_nav_menu_sections.vue', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TopNavNewDropdown, {
      propsData: {
        viewModel: TEST_VIEW_MODEL,
        ...props,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownContents = () =>
    findDropdown()
      .findAll('[data-testid]')
      .wrappers.map((child) => {
        const type = child.attributes('data-testid');

        if (type === 'divider') {
          return { type };
        } else if (type === 'header') {
          return { type, text: child.text() };
        }

        return {
          type,
          text: child.text(),
          href: child.attributes('href'),
        };
      });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders dropdown parent', () => {
      expect(findDropdown().props()).toMatchObject({
        text: TEST_VIEW_MODEL.title,
        textSrOnly: true,
        icon: 'plus',
      });
    });

    it('renders dropdown content', () => {
      expect(findDropdownContents()).toEqual([
        {
          type: 'header',
          text: TEST_VIEW_MODEL.menu_sections[0].title,
        },
        ...TEST_VIEW_MODEL.menu_sections[0].menu_items.map(({ title, href }) => ({
          type: 'item',
          href,
          text: title,
        })),
        {
          type: 'divider',
        },
        {
          type: 'header',
          text: TEST_VIEW_MODEL.menu_sections[1].title,
        },
        ...TEST_VIEW_MODEL.menu_sections[1].menu_items.map(({ title, href }) => ({
          type: 'item',
          href,
          text: title,
        })),
      ]);
    });
  });

  describe('with only 1 section', () => {
    beforeEach(() => {
      createComponent({
        viewModel: {
          ...TEST_VIEW_MODEL,
          menu_sections: TEST_VIEW_MODEL.menu_sections.slice(0, 1),
        },
      });
    });

    it('renders dropdown content without headers and dividers', () => {
      expect(findDropdownContents()).toEqual(
        TEST_VIEW_MODEL.menu_sections[0].menu_items.map(({ title, href }) => ({
          type: 'item',
          href,
          text: title,
        })),
      );
    });
  });
});
