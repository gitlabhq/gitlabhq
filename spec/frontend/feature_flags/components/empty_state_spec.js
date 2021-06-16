import { GlAlert, GlEmptyState, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import EmptyState from '~/feature_flags/components/empty_state.vue';

const DEFAULT_PROPS = {
  alerts: ['an alert', 'another alert'],
  isLoading: false,
  loadingLabel: 'test loading',
  errorState: false,
  errorTitle: 'test title',
  emptyState: false,
  emptyTitle: 'test empty',
  emptyDescription: 'empty description',
};

const DEFAULT_PROVIDE = {
  errorStateSvgPath: '/error.svg',
  featureFlagsHelpPagePath: '/help/page/path',
};

describe('feature_flags/components/feature_flags_tab.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    mount(
      {
        components: {
          EmptyState,
        },
        render(h) {
          return h(EmptyState, { props: this.$attrs, on: this.$listeners }, this.$slots.default);
        },
      },
      {
        propsData: {
          ...DEFAULT_PROPS,
          ...props,
        },
        provide: DEFAULT_PROVIDE,
        slots: {
          default: '<p data-testid="test-slot">testing</p>',
        },
      },
    );

  afterEach(() => {
    if (wrapper?.destroy) {
      wrapper.destroy();
    }

    wrapper = null;
  });

  describe('alerts', () => {
    let alerts;

    beforeEach(() => {
      wrapper = factory();
      alerts = wrapper.findAll(GlAlert);
    });

    it('should show any alerts', () => {
      expect(alerts).toHaveLength(DEFAULT_PROPS.alerts.length);
      alerts.wrappers.forEach((alert, i) => expect(alert.text()).toBe(DEFAULT_PROPS.alerts[i]));
    });

    it('should emit a dismiss event for a dismissed alert', () => {
      alerts.at(0).vm.$emit('dismiss');

      expect(wrapper.find(EmptyState).emitted('dismissAlert')).toEqual([[0]]);
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      wrapper = factory({ isLoading: true });
    });

    it('should show a loading icon and nothing else', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findAll(GlEmptyState)).toHaveLength(0);
    });
  });

  describe('error', () => {
    let emptyState;

    beforeEach(() => {
      wrapper = factory({ errorState: true });
      emptyState = wrapper.find(GlEmptyState);
    });

    it('should show an error state if there has been an error', () => {
      expect(emptyState.text()).toContain(DEFAULT_PROPS.errorTitle);
      expect(emptyState.text()).toContain(
        'Try again in a few moments or contact your support team.',
      );
      expect(emptyState.props('svgPath')).toBe(DEFAULT_PROVIDE.errorStateSvgPath);
    });
  });

  describe('empty', () => {
    let emptyState;
    let emptyStateLink;

    beforeEach(() => {
      wrapper = factory({ emptyState: true });
      emptyState = wrapper.find(GlEmptyState);
      emptyStateLink = emptyState.find(GlLink);
    });

    it('should show an empty state if it is empty', () => {
      expect(emptyState.text()).toContain(DEFAULT_PROPS.emptyTitle);
      expect(emptyState.text()).toContain(DEFAULT_PROPS.emptyDescription);
      expect(emptyState.props('svgPath')).toBe(DEFAULT_PROVIDE.errorStateSvgPath);
      expect(emptyStateLink.attributes('href')).toBe(DEFAULT_PROVIDE.featureFlagsHelpPagePath);
      expect(emptyStateLink.text()).toBe('More information');
    });
  });

  describe('slot', () => {
    let slot;

    beforeEach(async () => {
      wrapper = factory();
      await wrapper.vm.$nextTick();

      slot = wrapper.find('[data-testid="test-slot"]');
    });

    it('should display the passed slot', () => {
      expect(slot.exists()).toBe(true);
      expect(slot.text()).toBe('testing');
    });
  });
});
