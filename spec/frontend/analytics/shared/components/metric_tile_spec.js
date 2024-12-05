import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MetricTile from '~/analytics/shared/components/metric_tile.vue';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility');

describe('MetricTile', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(MetricTile, {
      propsData: {
        metric: {},
        ...props,
      },
    });
  };

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);
  const findPopover = () => wrapper.findComponent(MetricPopover);

  describe('template', () => {
    describe('links', () => {
      it('when the metric has links, it redirects the user on click', () => {
        const metric = {
          identifier: 'deploys',
          value: '10',
          label: 'Deploys',
          links: [{ url: 'foo/bar' }],
        };
        wrapper = createComponent({ metric });

        findSingleStat().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalledWith('foo/bar');
      });

      it("when the metric doesn't have links, it won't the user on click", () => {
        const metric = { identifier: 'deploys', value: '10', label: 'Deploys' };
        wrapper = createComponent({ metric });

        findSingleStat().vm.$emit('click');
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });

    describe('number formatting', () => {
      it(`will render 0 decimal places for an integer value`, () => {
        const metric = { identifier: 'deploys', value: '10', label: 'Deploys' };
        wrapper = createComponent({ metric });

        expect(findSingleStat().props('animationDecimalPlaces')).toBe(0);
      });

      it(`will render 1 decimal place for a float value`, () => {
        const metric = { identifier: 'deploys', value: '10.5', label: 'Deploys' };
        wrapper = createComponent({ metric });

        expect(findSingleStat().props('animationDecimalPlaces')).toBe(1);
      });

      it.each([10.53, 10.53324])(
        'will round to a maximum of 2 decimal place for a float value given %s',
        (value) => {
          const metric = { identifier: 'deploys', label: 'Deploys', value };
          wrapper = createComponent({ metric });

          expect(findSingleStat().props('animationDecimalPlaces')).toBe(2);
        },
      );

      it('will render using delimiters', () => {
        const metric = { identifier: 'deploys', value: '10000', label: 'Deploys' };
        wrapper = createComponent({ metric });

        expect(findSingleStat().props('useDelimiters')).toBe(true);
      });
    });

    it('renders a metric popover', () => {
      const metric = { identifier: 'deploys', value: '10', label: 'Deploys' };
      wrapper = createComponent({ metric });

      const popover = findPopover();
      expect(popover.exists()).toBe(true);
      expect(popover.props()).toMatchObject({ metric, target: metric.identifier });
    });
  });
});
