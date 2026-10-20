import { GlBadge, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import TrendPresenter from '~/glql/components/presenters/trend.vue';

describe('TrendPresenter', () => {
  let wrapper;

  const createComponent = ({ data }) => {
    wrapper = shallowMountExtended(TrendPresenter, {
      propsData: { data },
      directives: { GlTooltip: createMockDirective('gl-tooltip') },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('when the change is known', () => {
    beforeEach(() => {
      createComponent({
        data: {
          text: '5%',
          variant: 'success',
          metaIcon: 'arrow-up',
          metaTooltip: 'Up 5% from 20 in the previous period',
        },
      });
    });

    it('renders a badge with the change', () => {
      expect(findBadge().text()).toBe('5%');
      expect(findBadge().props()).toMatchObject({ variant: 'success', icon: 'arrow-up' });
    });

    it('passes the spelled-out direction to the tooltip', () => {
      expect(findBadge().attributes('title')).toBe('Up 5% from 20 in the previous period');
    });
  });

  describe('when the change is unknown', () => {
    beforeEach(() => {
      createComponent({ data: {} });
    });

    it('renders a dash instead of a badge', () => {
      expect(findBadge().exists()).toBe(false);
      expect(wrapper.findByTestId('trend-unknown').text()).toBe('—');
    });
  });

  describe('while the comparison is pending', () => {
    beforeEach(() => {
      createComponent({ data: { pending: true } });
    });

    it('renders a skeleton rather than the dash', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
      expect(wrapper.findByTestId('trend-unknown').exists()).toBe(false);
    });
  });
});
