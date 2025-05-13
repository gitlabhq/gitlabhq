import { GlIcon, GlLink, GlTooltip } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
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
      stubs: { GlTooltip: stubComponent(GlTooltip) },
    });
  };

  const findTooltipByTarget = (target) =>
    wrapper.findAllComponents(GlTooltip).wrappers.find((tooltip) => {
      return tooltip.props('target')() === target.element;
    });

  it('renders stat in div with icon and tooltip', () => {
    createComponent();

    const tooltip = findTooltipByTarget(wrapper);

    expect(wrapper.element.tagName).toBe('DIV');
    expect(wrapper.text()).toContain(defaultPropsData.stat);
    expect(tooltip.text()).toBe(defaultPropsData.tooltipText);
    expect(wrapper.findComponent(GlIcon).props('name')).toBe(defaultPropsData.iconName);
  });

  describe('when stat is clicked', () => {
    beforeEach(async () => {
      createComponent();
      await wrapper.trigger('click');
    });

    it('does not emit click event', () => {
      expect(wrapper.emitted('click')).toBeUndefined();
    });
  });

  describe('when tooltip is shown', () => {
    beforeEach(() => {
      createComponent();
      findTooltipByTarget(wrapper).vm.$emit('shown');
    });

    it('emits hover event', () => {
      expect(wrapper.emitted('hover')).toEqual([[]]);
    });
  });

  describe('when href prop is passed', () => {
    const href = 'http://gdk.test:3000/foo/bar/-/forks`';

    beforeEach(() => {
      createComponent({ propsData: { href } });
    });

    it('renders `GlLink` component', () => {
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(href);
    });

    describe('when link is clicked', () => {
      beforeEach(() => {
        wrapper.findComponent(GlLink).vm.$emit('click');
      });

      it('emits click event', () => {
        expect(wrapper.emitted('click')).toEqual([[]]);
      });
    });
  });
});
