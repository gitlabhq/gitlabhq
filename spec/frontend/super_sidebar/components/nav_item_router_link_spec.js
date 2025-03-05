import { RouterLinkStub } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import NavItemRouterLink from '~/super_sidebar/components/nav_item_router_link.vue';

describe('NavItemRouterLink component', () => {
  let wrapper;

  const createWrapper = ({ item, routerLinkSlotProps = {} }) => {
    wrapper = mountExtended(NavItemRouterLink, {
      propsData: {
        item,
      },
      stubs: {
        RouterLink: {
          ...RouterLinkStub,
          props: ['custom', 'activeClass', 'to'],
          render() {
            const children = this.$scopedSlots.default({
              href: '/foo',
              isActive: false,
              navigate: jest.fn(),
              ...routerLinkSlotProps,
            });
            return children[0];
          },
        },
      },
    });
  };

  const findRouterLink = () => wrapper.findComponent(RouterLinkStub);

  describe('when `RouterLink` is not active', () => {
    it('renders an anchor tag without active CSS class and `aria-current` attribute', () => {
      createWrapper({ item: { title: 'foo', to: { name: 'foo' } } });

      expect(findRouterLink().props('custom')).toEqual('');
      expect(findRouterLink().attributes()).toMatchObject({
        href: '/foo',
      });
    });
  });

  describe('when `RouterLink` is active', () => {
    it('renders an anchor tag with active CSS class and `aria-current="page"`', () => {
      createWrapper({
        item: { title: 'foo', to: { name: 'foo' } },
        routerLinkSlotProps: { isActive: true },
      });

      expect(findRouterLink().props()).toMatchObject({
        activeClass: 'super-sidebar-nav-item-current',
        custom: '',
      });
      expect(findRouterLink().attributes()).toEqual({
        href: '/foo',
        'aria-current': 'page',
      });
    });
  });
});
