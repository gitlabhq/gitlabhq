import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavItem from '~/super_sidebar/components/nav_item.vue';

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
});
