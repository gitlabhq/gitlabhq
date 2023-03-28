import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { CLICK_MENU_ITEM_ACTION, TRACKING_UNKNOWN_ID } from '~/super_sidebar/constants';

describe('NavItem component', () => {
  let wrapper;

  const findLink = () => wrapper.findByTestId('nav-item-link');
  const findPill = () => wrapper.findComponent(GlBadge);
  const createWrapper = (item, props = {}) => {
    wrapper = shallowMountExtended(NavItem, {
      propsData: {
        item,
        ...props,
      },
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

  describe('Data Tracking Attributes', () => {
    it('adds no labels on sections', () => {
      const id = 'my-id';
      createWrapper({ title: 'Foo', id, items: [{ title: 'Baz' }] });

      expect(findLink().attributes('data-track-action')).toBeUndefined();
      expect(findLink().attributes('data-track-label')).toBeUndefined();
      expect(findLink().attributes('data-track-extra')).toBeUndefined();
    });

    it('adds appropriate data tracking labels on links with ID', () => {
      const id = 'my-id';
      createWrapper({ title: 'Foo', id });

      expect(findLink().attributes('data-track-action')).toBe(CLICK_MENU_ITEM_ACTION);
      expect(findLink().attributes('data-track-label')).toBe(id);
      expect(findLink().attributes('data-track-extra')).toBeUndefined();
    });

    it('adds data tracking labels on links without id', () => {
      const title = 'Foo';
      createWrapper({ title });

      expect(findLink().attributes('data-track-action')).toBe(CLICK_MENU_ITEM_ACTION);
      expect(findLink().attributes('data-track-label')).toBe(TRACKING_UNKNOWN_ID);
      expect(findLink().attributes('data-track-extra')).toBe(JSON.stringify({ title }));
    });
  });
});
