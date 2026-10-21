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
  const findDescription = () => wrapper.findByTestId('trend-description');

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

    it('gives screen readers the spelled-out direction in place of the badge', () => {
      expect(findBadge().attributes('aria-hidden')).toBe('true');
      expect(findDescription().text()).toBe('Up 5% from 20 in the previous period');
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

    it('explains the dash in a tooltip', () => {
      expect(wrapper.findByTestId('trend-unknown').attributes('title')).toBe(
        'No data for the previous period',
      );
    });

    it('gives screen readers the explanation in place of the dash', () => {
      expect(wrapper.findByTestId('trend-unknown').attributes('aria-hidden')).toBe('true');
      expect(findDescription().text()).toBe('No data for the previous period');
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

    it('does not tell screen readers the previous period has no data', () => {
      expect(wrapper.findByTestId('trend-description').exists()).toBe(false);
    });
  });
});
