import { shallowMount, createLocalVue } from '@vue/test-utils';
import EmptyChart from '~/monitoring/components/charts/empty_chart.vue';

const localVue = createLocalVue();

describe('Empty Chart component', () => {
  let emptyChart;
  const graphTitle = 'Memory Usage';

  beforeEach(() => {
    emptyChart = shallowMount(localVue.extend(EmptyChart), {
      propsData: {
        graphTitle,
      },
      sync: false,
      localVue,
    });
  });

  afterEach(() => {
    emptyChart.destroy();
  });

  it('render the chart title', () => {
    expect(emptyChart.find({ ref: 'graphTitle' }).text()).toBe(graphTitle);
  });

  describe('Computed props', () => {
    it('sets the height for the svg container', () => {
      expect(emptyChart.vm.svgContainerStyle.height).toBe('300px');
    });
  });
});
