import { shallowMount } from '@vue/test-utils';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import ColumnChart from '~/monitoring/components/charts/column.vue';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockResolvedValue('mockSvgPathContent'),
}));

const yAxisName = 'Y-axis mock name';
const yAxisFormat = 'bytes';
const yAxisPrecistion = 3;
const dataValues = [
  [1495700554.925, '8.0390625'],
  [1495700614.925, '8.0390625'],
  [1495700674.925, '8.0390625'],
];

describe('Column component', () => {
  let wrapper;

  const findChart = () => wrapper.find(GlColumnChart);
  const chartProps = prop => findChart().props(prop);

  beforeEach(() => {
    wrapper = shallowMount(ColumnChart, {
      propsData: {
        graphData: {
          yAxis: {
            name: yAxisName,
            format: yAxisFormat,
            precision: yAxisPrecistion,
          },
          metrics: [
            {
              result: [
                {
                  metric: {},
                  values: dataValues,
                },
              ],
            },
          ],
        },
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('wrapped components', () => {
    describe('GitLab UI column chart', () => {
      it('is a Vue instance', () => {
        expect(findChart().isVueInstance()).toBe(true);
      });

      it('receives data properties needed for proper chart render', () => {
        expect(chartProps('data').values).toEqual(dataValues);
      });

      it('passes the y axis name correctly', () => {
        expect(chartProps('yAxisTitle')).toBe(yAxisName);
      });

      it('passes the y axis configuration correctly', () => {
        expect(chartProps('option').yAxis).toMatchObject({
          name: yAxisName,
          axisLabel: {
            formatter: expect.any(Function),
          },
          scale: false,
        });
      });

      it('passes a dataZoom configuration', () => {
        expect(chartProps('option').dataZoom).toBeDefined();
      });
    });
  });
});
