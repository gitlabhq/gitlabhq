import { nextTick } from 'vue';
import { GlBadge, GlButton, GlAvatar } from '@gitlab/ui';
import { RouterLinkStub } from '@vue/test-utils';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import NavItemLink from '~/super_sidebar/components/nav_item_link.vue';
import {
  NAV_ITEM_LINK_ACTIVE_CLASS,
  CLICK_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';

describe('NavItem component', () => {
  let wrapper;

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLink = () => wrapper.findByTestId('nav-item-link');
  const findPill = () => wrapper.findComponent(GlBadge);
  const findPinButton = () => wrapper.findComponent(GlButton);
  const findNavItemLink = () => extendedWrapper(wrapper.findComponent(NavItemLink));

  const createWrapper = ({
    item,
    props = {},
    provide = {},
    routerLinkSlotProps = {},
    directives = {},
  }) => {
    wrapper = mountExtended(NavItem, {
      propsData: {
        item,
        ...props,
      },
      provide,
      directives,
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

    it('does not render a pill when in icon-only mode', () => {
      createWrapper({ item: { title: 'Foo', pill_count: 123 }, provide: { isIconOnly: true } });
      expect(findPill().exists()).toBe(false);
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

    it.each([null, undefined, false, true, '', NaN, Number.POSITIVE_INFINITY])(
      'if `pill_count_field` field is `%s`, does not render pill',
      (value) => {
        createWrapper({
          item: {
            pill_count: 100,
            pill_count_field: 'test',
          },
          props: {
            asyncCount: {
              test: value,
            },
          },
        });
        expect(findPill().exists()).toBe(false);
      },
    );

    describe('if asyncCount `pill_count_field` exists, use it to get count', () => {
      it.each`
        pillCountField                       | result
        ${'openIssuesCount'}                 | ${0}
        ${'openIssuesCount'}                 | ${10}
        ${'openIssuesCount'}                 | ${'100.2k'}
        ${'todos'}                           | ${1}
        ${'assigned_issues'}                 | ${2}
        ${'assigned_merge_requests'}         | ${3}
        ${'review_requested_merge_requests'} | ${4}
        ${'total_merge_requests'}            | ${7}
      `(
        'returns `$result` when nav item `pill_count_field` is `$pillCountField` and count is `$result`',
        ({ pillCountField, result }) => {
          createWrapper({
            item: {
              pill_count: 100,
              pill_count_field: pillCountField,
            },
            props: {
              asyncCount: {
                [pillCountField]: result,
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

  describe('when `item` prop has `link` attribute', () => {
    describe('when `item` has `is_active` set to `false`', () => {
      it('renders `NavItemLink` with no active class', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: false } });

        expect(findNavItemLink().classes()).not.toContain(NAV_ITEM_LINK_ACTIVE_CLASS);
      });
    });

    describe('when `item` has `is_active` set to `true`', () => {
      it('renders `NavItemLink` with active class', () => {
        createWrapper({ item: { title: 'Foo', link: '/foo', is_active: true } });

        expect(findNavItemLink().classes()).toContain(NAV_ITEM_LINK_ACTIVE_CLASS);
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

  describe('title tooltip', () => {
    const directives = {
      GlTooltip: createMockDirective('gl-tooltip'),
    };

    it('does not show when sidebar is fully visible', () => {
      createWrapper({ item: { title: 'Foo' }, directives });
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip.value).toBe('');
    });

    it('shows when sidebar is in icon-only mode', () => {
      createWrapper({ item: { title: 'Foo' }, provide: { isIconOnly: true }, directives });
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');

      expect(tooltip.value).toBe('Foo');
    });
  });
});
