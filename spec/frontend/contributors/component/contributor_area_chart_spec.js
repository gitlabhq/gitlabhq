import { GlAreaChart } from '@gitlab/ui/src/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContributorAreaChart from '~/contributors/components/contributor_area_chart.vue';

describe('Contributor area chart', () => {
  let wrapper;

  const defaultProps = {
    data: [
      {
        name: 'Commits',
        data: [
          ['2015-01-01', 1],
          ['2015-01-02', 2],
          ['2015-01-03', 3],
        ],
      },
    ],
    height: 100,
    option: {
      xAxis: { name: '', type: 'time' },
      yAxis: { name: 'Number of commits' },
      grid: {
        top: 10,
        bottom: 10,
        left: 10,
        right: 10,
      },
    },
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ContributorAreaChart, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findTooltipTitle = () => wrapper.findByTestId('tooltip-title').text();
  const findTooltipLabels = () =>
    wrapper.findAllByTestId('tooltip-label').wrappers.map((w) => w.text());
  const findTooltipValues = () =>
    wrapper.findAllByTestId('tooltip-value').wrappers.map((w) => w.text());

  const setTooltipData = async (seriesData = [{ data: ['01-01-2000', 10] }]) => {
    findAreaChart().vm.formatTooltipText({ seriesData });
    await nextTick();
  };

  describe('default inputs', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the area chart', () => {
      expect(findAreaChart().exists()).toBe(true);
      expect(findAreaChart().props()).toMatchObject(defaultProps);
    });

    it('emits the area chart created event', () => {
      const payload = 'test';
      findAreaChart().vm.$emit('created', payload);

      expect(wrapper.emitted('created')).toHaveLength(1);
      expect(wrapper.emitted('created')[0]).toEqual([payload]);
    });

    it('shows the tooltip with the formatted chart data', async () => {
      await setTooltipData();

      expect(findTooltipTitle()).toBe('Jan 1, 2000');
      expect(findTooltipLabels()).toEqual([defaultProps.option.yAxis.name]);
      expect(findTooltipValues()).toEqual(['10']);
    });

    it('shows the tooltip with all formatted chart series', async () => {
      await setTooltipData([
        { seriesName: 'Additions', data: ['01-01-2000', 10] },
        { seriesName: 'Deletions', data: ['01-01-2000', 5] },
      ]);

      expect(findTooltipTitle()).toBe('Jan 1, 2000');
      expect(findTooltipLabels()).toEqual(['Additions', 'Deletions']);
      expect(findTooltipValues()).toEqual(['10', '5']);
    });
  });

  describe('Y axis has no name', () => {
    beforeEach(() => {
      createWrapper({
        option: {
          ...defaultProps.option,
          yAxis: {},
        },
      });
    });

    it('shows a default tooltip label if the Y axis name is missing', async () => {
      await setTooltipData();

      expect(findTooltipLabels()).toEqual(['Value']);
    });
  });
});
