import { GlSingleStat } from '@gitlab/ui/src/charts';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SingleStat from '~/analytics/analytics_dashboards/components/visualizations/single_stat.vue';

describe('Single Stat Visualization', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(SingleStat, {
      propsData: {
        data: props.data,
        options: props.options,
      },
    });
  };

  describe('when mounted', () => {
    it('should render the single stat with default props', () => {
      createWrapper();

      expect(findSingleStat().props()).toMatchObject({
        value: 0,
        title: '',
        variant: 'neutral',
        shouldAnimate: true,
        animationDecimalPlaces: 0,
        useDelimiters: true,
      });
    });

    it('should pass the visualization data to the single stat value', () => {
      createWrapper({ data: 35 });

      expect(findSingleStat().props('value')).toBe(35);
    });

    describe('when there are user defined options that include decimal places', () => {
      const options = {
        title: 'Sessions',
        decimalPlaces: 2,
        metaText: 'meta text',
        metaIcon: 'project',
        titleIcon: 'users',
        unit: 'days',
        variant: 'success',
      };

      it('should pass the visualization options to the single stat', () => {
        createWrapper({ options });

        expect(findSingleStat().props()).toMatchObject({
          title: 'Sessions',
          metaText: 'meta text',
          metaIcon: 'project',
          titleIcon: 'users',
          unit: 'days',
          variant: 'success',
        });
      });

      it.each`
        data         | animationDecimalPlaces
        ${undefined} | ${0}
        ${35}        | ${options.decimalPlaces}
      `(
        'should display $animationDecimalPlaces decimal places when the data is "$data"',
        ({ data, animationDecimalPlaces }) => {
          createWrapper({ data, options });

          expect(findSingleStat().props()).toMatchObject({ animationDecimalPlaces });
        },
      );
    });
  });
});
