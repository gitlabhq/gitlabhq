import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { INDIVIDUAL_CHART_HEIGHT } from '~/contributors/constants';
import IndividualChart from '~/contributors/components/individual_chart.vue';
import ContributorAreaChart from '~/contributors/components/contributor_area_chart.vue';

describe('Individual chart', () => {
  let wrapper;
  let mockChart;

  const commitData = [
    ['2010-04-15', 5],
    ['2010-05-15', 5],
    ['2010-06-15', 5],
    ['2010-07-15', 5],
    ['2010-08-15', 5],
  ];

  const defaultContributor = {
    name: 'Razputin Aquato',
    email: 'razputin.aquato@psychonauts.com',
    commits: 25,
    dates: [{ name: 'Commits', data: commitData }],
  };

  const findHeader = () => wrapper.findByTestId('chart-header');
  const findCommitCount = () => wrapper.findByTestId('commit-count');
  const findContributorAreaChart = () => wrapper.findComponent(ContributorAreaChart);

  const createWrapper = (props = {}) => {
    mockChart = { setOption: jest.fn() };

    wrapper = shallowMountExtended(IndividualChart, {
      propsData: {
        contributor: defaultContributor,
        chartOptions: {},
        zoom: {},
        ...props,
      },
    });

    findContributorAreaChart().vm.$emit('created', mockChart);
  };

  describe('when not zoomed', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the contributor name as the chart header', () => {
      expect(findHeader().text()).toBe(defaultContributor.name);
    });

    it('shows the total commit count', () => {
      const { commits, email } = defaultContributor;
      expect(findCommitCount().text()).toBe(`${commits} commits (${email})`);
    });

    it('renders the area chart with the given options', () => {
      expect(findContributorAreaChart().props()).toMatchObject({
        data: defaultContributor.dates,
        option: {},
        height: INDIVIDUAL_CHART_HEIGHT,
      });
    });
  });

  describe('when zoomed', () => {
    const zoom = {
      startValue: new Date('2010-05-01').getTime(),
      endValue: new Date('2010-08-01').getTime(),
    };

    beforeEach(() => {
      createWrapper({ zoom });
    });

    it('shows only the commits for the zoomed time period', () => {
      const { email } = defaultContributor;
      expect(findCommitCount().text()).toBe(`15 commits (${email})`);
    });

    it('sets the dataZoom chart option', () => {
      const { startValue, endValue } = zoom;
      expect(mockChart.setOption).toHaveBeenCalledWith(
        { dataZoom: { startValue, endValue, show: false } },
        { lazyUpdate: true },
      );
    });

    describe('when zoom is changed', () => {
      const newZoom = {
        startValue: new Date('2010-04-01').getTime(),
        endValue: new Date('2010-05-01').getTime(),
      };

      beforeEach(() => {
        wrapper.setProps({ zoom: newZoom });
      });

      it('shows only the commits for the zoomed time period', () => {
        const { email } = defaultContributor;
        expect(findCommitCount().text()).toBe(`5 commits (${email})`);
      });

      it('sets the dataZoom chart option', () => {
        const { startValue, endValue } = newZoom;
        expect(mockChart.setOption).toHaveBeenCalledWith(
          { dataZoom: { startValue, endValue, show: false } },
          { lazyUpdate: true },
        );
      });
    });
  });
});
