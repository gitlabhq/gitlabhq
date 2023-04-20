import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import {
  CLICK_MENU_ITEM_ACTION,
  TRACKING_UNKNOWN_ID,
  TRACKING_UNKNOWN_PANEL,
} from '~/super_sidebar/constants';

describe('NavItem component', () => {
  let wrapper;

  const findLink = () => wrapper.findByTestId('nav-item-link');
  const findPill = () => wrapper.findComponent(GlBadge);
  const createWrapper = (item, props = {}, provide = {}) => {
    wrapper = shallowMountExtended(NavItem, {
      propsData: {
        item,
        ...props,
      },
      provide,
    });
  };

  describe('pills', () => {
    it.each([0, 5, 3.4, 'foo', '10%'])('item with pill_data `%p` renders a pill', (pillCount) => {
      createWrapper({ title: 'Foo', pill_count: pillCount });

      expect(findPill().text()).toEqual(pillCount.toString());
    });

    it.each([null, undefined, false, true, '', NaN, Number.POSITIVE_INFINITY])(
      'item with pill_data `%p` renders no pill',
      (pillCount) => {
        createWrapper({ title: 'Foo', pill_count: pillCount });

        expect(findPill().exists()).toEqual(false);
      },
    );
  });

  it('applies custom link classes', () => {
    const customClass = 'customClass';
    createWrapper(
      { title: 'Foo' },
      {
        linkClasses: {
          [customClass]: true,
        },
      },
    );

    expect(findLink().attributes('class')).toContain(customClass);
  });

  it('applies custom classes set in the backend', () => {
    const customClass = 'customBackendClass';
    createWrapper({ title: 'Foo', link_classes: customClass });

    expect(findLink().attributes('class')).toContain(customClass);
  });

  describe('Data Tracking Attributes', () => {
    it('adds no labels on sections', () => {
      const id = 'my-id';
      createWrapper({ title: 'Foo', id, items: [{ title: 'Baz' }] });

      expect(findLink().attributes('data-track-action')).toBeUndefined();
      expect(findLink().attributes('data-track-label')).toBeUndefined();
      expect(findLink().attributes('data-track-property')).toBeUndefined();
      expect(findLink().attributes('data-track-extra')).toBeUndefined();
    });

    it.each`
      id           | panelType    | eventLabel             | eventProperty             | eventExtra
      ${'abc'}     | ${'xyz'}     | ${'abc'}               | ${'nav_panel_xyz'}        | ${undefined}
      ${undefined} | ${'xyz'}     | ${TRACKING_UNKNOWN_ID} | ${'nav_panel_xyz'}        | ${'{"title":"Foo"}'}
      ${'abc'}     | ${undefined} | ${'abc'}               | ${TRACKING_UNKNOWN_PANEL} | ${'{"title":"Foo"}'}
      ${undefined} | ${undefined} | ${TRACKING_UNKNOWN_ID} | ${TRACKING_UNKNOWN_PANEL} | ${'{"title":"Foo"}'}
    `(
      'adds appropriate data tracking labels for id=$id and panelType=$panelType',
      ({ id, eventLabel, panelType, eventProperty, eventExtra }) => {
        createWrapper({ title: 'Foo', id }, {}, { panelType });

        expect(findLink().attributes('data-track-action')).toBe(CLICK_MENU_ITEM_ACTION);
        expect(findLink().attributes('data-track-label')).toBe(eventLabel);
        expect(findLink().attributes('data-track-property')).toBe(eventProperty);
        expect(findLink().attributes('data-track-extra')).toBe(eventExtra);
      },
    );
  });
});
