import { GlChartSeriesLabel } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FormattedTooltipContent from '~/glql/components/presenters/chart/formatted_tooltip_content.vue';

describe('FormattedTooltipContent', () => {
  let wrapper;

  const createComponent = ({ content, formatValue }) => {
    wrapper = shallowMountExtended(FormattedTooltipContent, {
      propsData: { content, formatValue },
    });
  };

  it('renders one row per series with the provided formatter applied', () => {
    createComponent({
      content: {
        'Success rate': { value: 0.819, color: '#aaa' },
        p95: { value: 5252, color: '#bbb' },
      },
      formatValue: (label, value) => `${label}=${value}`,
    });

    const rows = wrapper.findAll('.gl-charts-tooltip-default-format-series');
    expect(rows).toHaveLength(2);
    expect(rows.at(0).text()).toContain('Success rate=0.819');
    expect(rows.at(1).text()).toContain('p95=5252');
  });

  it('passes each series color to GlChartSeriesLabel', () => {
    createComponent({
      content: { foo: { value: 1, color: '#abc' } },
      formatValue: (_label, value) => String(value),
    });

    expect(wrapper.findComponent(GlChartSeriesLabel).props('color')).toBe('#abc');
  });

  it('renders nothing when content is empty', () => {
    createComponent({ content: {}, formatValue: () => '' });

    expect(wrapper.findAll('.gl-charts-tooltip-default-format-series')).toHaveLength(0);
  });
});
