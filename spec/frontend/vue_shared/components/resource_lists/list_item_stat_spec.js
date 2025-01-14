import { GlIcon, GlLink } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItemStat from '~/vue_shared/components/resource_lists/list_item_stat.vue';

describe('ListItemStat', () => {
  let wrapper;

  const defaultPropsData = {
    tooltipText: 'Subgroups',
    iconName: 'subgroup',
    stat: '23',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(ListItemStat, {
      propsData: { ...defaultPropsData, ...propsData },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  it('renders stat in div with icon and tooltip', () => {
    createComponent();

    const tooltip = getBinding(wrapper.element, 'gl-tooltip');

    expect(wrapper.element.tagName).toBe('DIV');
    expect(wrapper.text()).toBe(defaultPropsData.stat);
    expect(tooltip.value).toBe(defaultPropsData.tooltipText);
    expect(wrapper.findComponent(GlIcon).props('name')).toBe(defaultPropsData.iconName);
  });

  describe('when href prop is passed', () => {
    const href = 'http://gdk.test:3000/foo/bar/-/forks`';

    beforeEach(() => {
      createComponent({ propsData: { href } });
    });

    it('renders `GlLink` component', () => {
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(href);
    });
  });
});
