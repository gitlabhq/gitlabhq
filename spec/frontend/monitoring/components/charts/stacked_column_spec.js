import { shallowMount } from '@vue/test-utils';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import StackedColumnChart from '~/monitoring/components/charts/stacked_column.vue';
import { stackedColumnMockedData } from '../../mock_data';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

describe('Stacked column chart component', () => {
  let wrapper;
  const glStackedColumnChart = () => wrapper.find(GlStackedColumnChart);

  beforeEach(() => {
    wrapper = shallowMount(StackedColumnChart, {
      propsData: {
        graphData: stackedColumnMockedData,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with graphData present', () => {
    it('is a Vue instance', () => {
      expect(glStackedColumnChart().exists()).toBe(true);
    });

    it('should contain the same number of elements in the seriesNames computed prop as the graphData metrics prop', () =>
      wrapper.vm
        .$nextTick()
        .then(expect(wrapper.vm.seriesNames).toHaveLength(stackedColumnMockedData.metrics.length)));

    it('should contain the same number of elements in the groupBy computed prop as the graphData result prop', () =>
      wrapper.vm
        .$nextTick()
        .then(
          expect(wrapper.vm.groupBy).toHaveLength(
            stackedColumnMockedData.metrics[0].result[0].values.length,
          ),
        ));
  });
});
