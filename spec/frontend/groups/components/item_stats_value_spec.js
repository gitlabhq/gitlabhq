import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ItemStatsValue from '~/groups/components/item_stats_value.vue';

describe('ItemStatsValue', () => {
  let wrapper;

  const defaultProps = {
    title: 'Subgroups',
    cssClass: 'number-subgroups',
    iconName: 'folder',
    tooltipPlacement: 'left',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ItemStatsValue, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findStatValue = () => wrapper.find('[data-testid="itemStatValue"]');

  describe('template', () => {
    describe('when `value` is not provided', () => {
      it('does not render value count', () => {
        createComponent();

        expect(findStatValue().exists()).toBe(false);
      });
    });

    describe('when `value` is provided', () => {
      beforeEach(() => {
        createComponent({
          value: 10,
        });
      });

      it('renders component element correctly', () => {
        expect(wrapper.classes()).toContain('number-subgroups');
      });

      it('renders element tooltip correctly', () => {
        expect(wrapper.attributes('title')).toBe('Subgroups');
        expect(wrapper.attributes('data-placement')).toBe('left');
      });

      it('renders element icon correctly', () => {
        expect(findGlIcon().exists()).toBe(true);
        expect(findGlIcon().props('name')).toBe('folder');
      });

      it('renders value count correctly', () => {
        expect(findStatValue().classes()).toContain('stat-value');
        expect(findStatValue().text()).toBe('10');
      });
    });
  });
});
