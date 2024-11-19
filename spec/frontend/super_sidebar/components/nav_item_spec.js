import { nextTick } from 'vue';
import { GlBadge, GlButton, GlAvatar } from '@gitlab/ui';
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
import eventHub from '~/super_sidebar/event_hub';

describe('NavItem component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLink = () => wrapper.findByTestId('nav-item-link');
  const findPill = () => wrapper.findComponent(GlBadge);
  const findPinButton = () => wrapper.findComponent(GlButton);
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
          render(h) {
            const children = this.$scopedSlots.default({
              href: '/foo',
              isActive: false,
              navigate: jest.fn(),
              ...routerLinkSlotProps,
            });
            return h('a', children);
          },
        },
      },
    });
  };

  describe('pills', () => {
    it.each([0, 5, 3.4, 'foo', '10%'])('item with pill_count `%p` renders a pill', (pillCount) => {
      createWrapper({ item: { title: 'Foo', pill_count: pillCount } });

      expect(findPill().text()).toBe(pillCount.toString());
    });

    it.each([null, undefined, false, true, '', NaN, Number.POSITIVE_INFINITY])(
      'item with pill_data `%p` renders no pill',
      (pillCount) => {
        createWrapper({ item: { title: 'Foo', pill_count: pillCount } });

        expect(findPill().exists()).toBe(false);
      },
    );

    describe('updating pill value', () => {
      const initialPillValue = '20%';
      const updatedPillValue = '50%';
      const itemIdForUpdate = '_some_item_id_';
      const triggerPillValueUpdate = async ({
        value = updatedPillValue,
        itemId = itemIdForUpdate,
      } = {}) => {
        eventHub.$emit('updatePillValue', { value, itemId });
        await nextTick();
      };

      it('updates the pill count', async () => {
        createWrapper({ item: { id: itemIdForUpdate, pill_count: initialPillValue } });

        await triggerPillValueUpdate();

        expect(findPill().text()).toBe(updatedPillValue);
      });

      it('does not update the pill count for non matching item id', async () => {
        createWrapper({ item: { id: '_non_matching_id_', pill_count: initialPillValue } });

        await triggerPillValueUpdate();

        expect(findPill().text()).toBe(initialPillValue);
      });
    });

    describe('async updating pill prop', () => {
      it('re-renders item with when prop pill_count changes', async () => {
        createWrapper({ item: { title: 'Foo', pill_count: 0 } });

        expect(findPill().text()).toBe('0');

        // https://gitlab.com/gitlab-org/gitlab/-/issues/428246
        // This is testing specific async behaviour that was before missed
        await wrapper.setProps({ item: { title: 'Foo', pill_count: 10 } });
        expect(findPill().text()).toBe('10');
      });
    });

    describe('if `pill_count_field` exists, use it to get async count', () => {
      it.each`
        pillCountField              | asyncCountValue | result
        ${'openIssuesCount'}        | ${0}            | ${0}
        ${'openIssuesCount'}        | ${10}           | ${10}
        ${'openIssuesCount'}        | ${100234}       | ${'100.2k'}
        ${'openMergeRequestsCount'} | ${0}            | ${0}
        ${'openMergeRequestsCount'} | ${10}           | ${10}
        ${'openMergeRequestsCount'} | ${100234}       | ${'100.2k'}
      `(
        'returns `$result` when nav item `pill_count_field` is `$pillCountField` and count is `$asyncCountValue`',
        ({ pillCountField, asyncCountValue, result }) => {
          createWrapper({
            item: {
              pill_count: 0,
              pill_count_field: pillCountField,
            },
            props: {
              asyncCount: {
                [pillCountField]: asyncCountValue,
              },
            },
          });
          expect(findPill().text()).toBe(`${result}`);
        },
      );
    });

    describe('if `pill_count_field` does not exist, use `pill_count` value`', () => {
      it('renders `pill_count_field` value based on item type', () => {
        createWrapper({ item: { title: 'Foo', pill_count: 10, pill_count_field: null } });

        expect(findPill().text()).toBe('10');
      });
    });
  });

  describe('destroyed', () => {
    it('should unbind event listeners on eventHub', async () => {
      jest.spyOn(eventHub, '$off');

      createWrapper({ item: {} });
      await wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith('updatePillValue', expect.any(Function));
    });
  });

  describe('pins', () => {
    describe('when pins are not supported', () => {
      it('does not render pin button', () => {
        createWrapper({
          item: { title: 'Foo' },
          provide: {
            panelSupportsPins: false,
          },
        });

        expect(findPinButton().exists()).toBe(false);
      });
    });

    describe('when pins are supported', () => {
      beforeEach(() => {
        createWrapper({
          item: { title: 'Foo' },
          provide: {
            panelSupportsPins: true,
          },
        });
      });

      it('renders pin button', () => {
        expect(findPinButton().exists()).toBe(true);
      });

      it('contains an aria-label', () => {
        expect(findPinButton().attributes('aria-label')).toBe('Pin Foo');
      });

      it('toggles pointer events on after CSS fade-in', async () => {
        const pinButton = findPinButton();

        expect(pinButton.classes()).toContain('gl-pointer-events-none');

        wrapper.trigger('mouseenter');
        pinButton.vm.$emit('transitionend');
        await nextTick();

        expect(pinButton.classes()).not.toContain('gl-pointer-events-none');
      });

      it('does not toggle pointer events if mouse leaves before CSS fade-in ends', async () => {
        const pinButton = findPinButton();

        expect(pinButton.classes()).toContain('gl-pointer-events-none');

        wrapper.trigger('mouseenter');
        wrapper.trigger('mousemove');
        wrapper.trigger('mouseleave');
        pinButton.vm.$emit('transitionend');
        await nextTick();

        expect(pinButton.classes()).toContain('gl-pointer-events-none');
      });
    });
  });

  it('applies correct aria-label', () => {
    const titleString = 'Hello, world!';
    createWrapper({
      item: { title: titleString },
    });

    expect(findLink().attributes('aria-label')).toEqual(titleString);
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

  it('applies data-method specified in the backend', () => {
    const method = 'post';
    createWrapper({ item: { title: 'Foo', data_method: method } });

    expect(findLink().attributes('data-method')).toContain(method);
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
          'gl-opacity-0',
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
          'gl-opacity-10',
        );
      });
    });
  });

  describe('when `item` prop has `link` attribute', () => {
    describe('when `item` has `is_active` set to `false`', () => {
      it('renders `NavItemLink` with active indicator hidden', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: false } });

        expect(findNavItemLink().findByTestId('active-indicator').classes()).toContain(
          'gl-opacity-0',
        );
      });
    });

    describe('when `item` has `is_active` set to `true`', () => {
      it('renders `NavItemLink` with active indicator shown', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: true } });

        expect(findNavItemLink().findByTestId('active-indicator').classes()).toContain(
          'gl-opacity-10',
        );
      });
    });
  });

  describe('when `item` prop has `entity_id` attribute', () => {
    it('renders an avatar', () => {
      createWrapper({
        item: { title: 'Foo', entity_id: 123, avatar: '/avatar.png', avatar_shape: 'circle' },
      });

      expect(findAvatar().props()).toMatchObject({
        entityId: 123,
        shape: 'circle',
        src: '/avatar.png',
      });
    });
  });

  describe('when `item.is_active` is true', () => {
    it('scrolls into view', () => {
      createWrapper({
        item: { is_active: true },
      });
      expect(wrapper.element.scrollIntoView).toHaveBeenNthCalledWith(1, {
        behavior: 'instant',
        block: 'center',
        inline: 'nearest',
      });
    });
  });

  describe('when `item.is_active` is false', () => {
    it('scrolls not into view', () => {
      createWrapper({
        item: { is_active: false },
      });
      expect(wrapper.element.scrollIntoView).not.toHaveBeenCalled();
    });
  });
});
