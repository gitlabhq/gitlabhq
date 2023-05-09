import { GlBadge } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import NavItemRouterLink from '~/super_sidebar/components/nav_item_router_link.vue';
import NavItemLink from '~/super_sidebar/components/nav_item_link.vue';
import {
  CLICK_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';

describe('NavItem component', () => {
  let wrapper;

  const findLink = () => wrapper.findByTestId('nav-item-link');
  const findPill = () => wrapper.findComponent(GlBadge);
  const findNavItemRouterLink = () => extendedWrapper(wrapper.findComponent(NavItemRouterLink));
  const findNavItemLink = () => extendedWrapper(wrapper.findComponent(NavItemLink));

  const createWrapper = ({ item, props = {}, provide = {}, routerLinkSlotProps = {} }) => {
    wrapper = mountExtended(NavItem, {
      propsData: {
        item,
        ...props,
      },
      provide,
      stubs: {
        RouterLink: {
          ...RouterLinkStub,
          render() {
            const children = this.$scopedSlots.default({
              href: '/foo',
              isActive: false,
              navigate: jest.fn(),
              ...routerLinkSlotProps,
            });
            return children;
          },
        },
      },
    });
  };

  describe('pills', () => {
    it.each([0, 5, 3.4, 'foo', '10%'])('item with pill_data `%p` renders a pill', (pillCount) => {
      createWrapper({ item: { title: 'Foo', pill_count: pillCount } });

      expect(findPill().text()).toEqual(pillCount.toString());
    });

    it.each([null, undefined, false, true, '', NaN, Number.POSITIVE_INFINITY])(
      'item with pill_data `%p` renders no pill',
      (pillCount) => {
        createWrapper({ item: { title: 'Foo', pill_count: pillCount } });

        expect(findPill().exists()).toEqual(false);
      },
    );
  });

  it('applies custom link classes', () => {
    const customClass = 'customClass';
    createWrapper({
      item: { title: 'Foo' },
      props: {
        linkClasses: {
          [customClass]: true,
        },
      },
    });

    expect(findLink().attributes('class')).toContain(customClass);
  });

  it('applies custom classes set in the backend', () => {
    const customClass = 'customBackendClass';
    createWrapper({ item: { title: 'Foo', link_classes: customClass } });

    expect(findLink().attributes('class')).toContain(customClass);
  });

  describe('Data Tracking Attributes', () => {
    it.each`
      id           | panelType    | eventLabel             | eventProperty             | eventExtra
      ${'abc'}     | ${'xyz'}     | ${'abc'}               | ${'nav_panel_xyz'}        | ${undefined}
      ${undefined} | ${'xyz'}     | ${TRACKING_UNKNOWN_ID} | ${'nav_panel_xyz'}        | ${'{"title":"Foo"}'}
      ${'abc'}     | ${undefined} | ${'abc'}               | ${TRACKING_UNKNOWN_PANEL} | ${'{"title":"Foo"}'}
      ${undefined} | ${undefined} | ${TRACKING_UNKNOWN_ID} | ${TRACKING_UNKNOWN_PANEL} | ${'{"title":"Foo"}'}
    `(
      'adds appropriate data tracking labels for id=$id and panelType=$panelType',
      ({ id, eventLabel, panelType, eventProperty, eventExtra }) => {
        createWrapper({ item: { title: 'Foo', id }, props: {}, provide: { panelType } });

        expect(findLink().attributes('data-track-action')).toBe(CLICK_MENU_ITEM_ACTION);
        expect(findLink().attributes('data-track-label')).toBe(eventLabel);
        expect(findLink().attributes('data-track-property')).toBe(eventProperty);
        expect(findLink().attributes('data-track-extra')).toBe(eventExtra);
      },
    );
  });

  describe('when `item` prop has `to` attribute', () => {
    describe('when `RouterLink` is not active', () => {
      it('renders `NavItemRouterLink` with active indicator hidden', () => {
        createWrapper({ item: { title: 'Foo', to: { name: 'foo' } } });

        expect(findNavItemRouterLink().findByTestId('active-indicator').classes()).toContain(
          'gl-bg-transparent',
        );
      });
    });

    describe('when `RouterLink` is active', () => {
      it('renders `NavItemRouterLink` with active indicator shown', () => {
        createWrapper({
          item: { title: 'Foo', to: { name: 'foo' } },
          routerLinkSlotProps: { isActive: true },
        });

        expect(findNavItemRouterLink().findByTestId('active-indicator').classes()).toContain(
          'gl-bg-blue-500',
        );
      });
    });
  });

  describe('when `item` prop has `link` attribute', () => {
    describe('when `item` has `is_active` set to `false`', () => {
      it('renders `NavItemLink` with active indicator hidden', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: false } });

        expect(findNavItemLink().findByTestId('active-indicator').classes()).toContain(
          'gl-bg-transparent',
        );
      });
    });

    describe('when `item` has `is_active` set to `true`', () => {
      it('renders `NavItemLink` with active indicator shown', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: true } });

        expect(findNavItemLink().findByTestId('active-indicator').classes()).toContain(
          'gl-bg-blue-500',
        );
      });
    });
  });
});
