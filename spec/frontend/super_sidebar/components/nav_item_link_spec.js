import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavItemLink from '~/super_sidebar/components/nav_item_link.vue';

describe('NavItemLink component', () => {
  let wrapper;

  const createWrapper = (item) => {
    wrapper = shallowMountExtended(NavItemLink, {
      propsData: {
        item,
      },
    });
  };

  describe('when `item` has `is_active` set to `false`', () => {
    it('renders an anchor tag without active CSS class and `aria-current` attribute', () => {
      createWrapper({ title: 'foo', link: '/foo', is_active: false });

      expect(wrapper.attributes()).toEqual({
        href: '/foo',
        class: '',
      });
    });
  });

  describe('when `item` has `is_active` set to `true`', () => {
    it('renders an anchor tag with active CSS class and `aria-current="page"`', () => {
      createWrapper({ title: 'foo', link: '/foo', is_active: true });

      expect(wrapper.attributes()).toEqual({
        href: '/foo',
        class: 'super-sidebar-nav-item-current',
        'aria-current': 'page',
      });
    });
  });
});
