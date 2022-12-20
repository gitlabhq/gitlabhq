import { mount } from '@vue/test-utils';
import StrategyLabel from '~/feature_flags/components/strategy_label.vue';

const DEFAULT_PROPS = {
  name: 'All Users',
  parameters: 'parameters',
  scopes: 'scope1, scope2',
};

describe('feature_flags/components/feature_flags_tab.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    mount(
      {
        components: {
          StrategyLabel,
        },
        render(h) {
          return h(StrategyLabel, { props: this.$attrs, on: this.$listeners }, this.$slots.default);
        },
      },
      {
        propsData: {
          ...DEFAULT_PROPS,
          ...props,
        },
      },
    );

  describe('render', () => {
    let strategyLabel;

    beforeEach(() => {
      wrapper = factory({});
      strategyLabel = wrapper.findComponent(StrategyLabel);
    });

    it('should show the strategy label with parameters and scope', () => {
      expect(strategyLabel.text()).toContain(DEFAULT_PROPS.name);
      expect(strategyLabel.text()).toContain(DEFAULT_PROPS.parameters);
      expect(strategyLabel.text()).toContain(DEFAULT_PROPS.scopes);
      expect(strategyLabel.text()).toContain('All Users - parameters: scope1, scope2');
    });
  });

  describe('without parameters', () => {
    let strategyLabel;

    beforeEach(() => {
      wrapper = factory({ parameters: null });
      strategyLabel = wrapper.findComponent(StrategyLabel);
    });

    it('should hide empty params and dash', () => {
      expect(strategyLabel.text()).toContain(DEFAULT_PROPS.name);
      expect(strategyLabel.text()).not.toContain(' - ');
      expect(strategyLabel.text()).toContain('All Users: scope1, scope2');
    });
  });
});
