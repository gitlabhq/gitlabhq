import { GlChart } from '@gitlab/ui/src/charts';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getSystemColorScheme } from '~/lib/utils/css_utils';
import HeatMapChart, {
  labelColorOn,
} from '~/analytics/analytics_dashboards/components/visualizations/heat_map_chart.vue';

jest.mock('~/lib/utils/css_utils', () => ({
  ...jest.requireActual('~/lib/utils/css_utils'),
  getSystemColorScheme: jest.fn(() => 'gl-light'),
  listenSystemColorSchemeChange: jest.fn(),
  removeListenerSystemColorSchemeChange: jest.fn(),
}));

const CELLS = [
  { column: 'Chat', row: 'Power (100+)', value: 17024 },
  { column: 'Code Review', row: 'Power (100+)', value: 355 },
  { column: 'Chat', row: 'Heavy (25-99)', value: 12008 },
  { column: 'Code Review', row: 'Heavy (25-99)', value: 202 },
];

// The auto-stub renders only the default slot, which would hide the title.
const popoverStub = {
  name: 'GlPopover',
  props: ['show'],
  template: '<div><slot name="title"></slot><slot></slot></div>',
};

// Stands in for the ECharts instance handed over by GlChart's `created` event.
const fakeChart = () => {
  const handlers = {};
  const queries = {};

  return {
    // ECharts takes an optional query between the event name and the handler.
    on: (event, query, handler) => {
      handlers[event] = handler ?? query;
      queries[event] = handler ? query : undefined;
      return undefined;
    },
    off: jest.fn(),
    convertToPixel: jest.fn(() => [120, 48]),
    queryFor: (event) => queries[event],
    trigger: (event, payload) => handlers[event]?.(payload),
  };
};

describe('HeatMapChart', () => {
  let wrapper;
  let chart;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(HeatMapChart, {
      propsData: { data: CELLS, ...props },
      stubs: { GlPopover: popoverStub },
    });
    chart = fakeChart();
    wrapper.findComponent(GlChart).vm.$emit('created', chart);
  };

  const chartOptions = () => wrapper.findComponent(GlChart).props('options');
  const series = () => chartOptions().series;
  const findPopover = () => wrapper.findComponent({ name: 'GlPopover' });
  const cellWithValue = (value) => series().data.find((cell) => cell.value[2] === value);

  beforeEach(() => {
    createComponent();
  });

  it('renders a heatmap series', () => {
    expect(wrapper.findComponent(GlChart).exists()).toBe(true);
    expect(series().type).toBe('heatmap');
  });

  it('puts the columns and rows on the category axes in first-appearance order', () => {
    expect(chartOptions().xAxis.data).toEqual(['Chat', 'Code Review']);
    expect(chartOptions().yAxis.data).toEqual(['Power (100+)', 'Heavy (25-99)']);
  });

  it('maps the cells to [column, row, value] triples', () => {
    expect(series().data.map(({ value }) => value)).toEqual([
      [0, 0, 17024],
      [1, 0, 355],
      [0, 1, 12008],
      [1, 1, 202],
    ]);
  });

  it('renders a pair missing from the data as a zero-value cell', () => {
    createComponent({ data: CELLS.slice(0, 3) });

    expect(series().data.map(({ value }) => value)).toEqual([
      [0, 0, 17024],
      [1, 0, 355],
      [0, 1, 12008],
      [1, 1, 0],
    ]);
  });

  it('renders an empty grid when given no cells', () => {
    createComponent({ data: [] });

    expect(series().data).toEqual([]);
    expect(chartOptions().xAxis.data).toEqual([]);
    expect(chartOptions().yAxis.data).toEqual([]);
  });

  it('keeps a row label that contains the column separator distinct', () => {
    createComponent({
      data: [
        { column: 'b', row: 'a', value: 1 },
        { column: '', row: 'a b', value: 2 },
      ],
    });

    expect(series().data.map(({ value }) => value)).toEqual([
      [0, 0, 1],
      [1, 0, 0],
      [0, 1, 0],
      [1, 1, 2],
    ]);
  });

  it('renders no legend', () => {
    expect(chartOptions().legend).toBeUndefined();
  });

  describe('visual map', () => {
    it('declares a hidden piecewise visual map', () => {
      const { visualMap } = chartOptions();

      expect(visualMap.show).toBe(false);
      expect(visualMap.type).toBe('piecewise');
    });

    it('reserves a neutral for zero and shades every real value blue', () => {
      const { pieces } = chartOptions().visualMap;

      // CELLS holds four distinct values, so four bands are used, spread
      // across the ramp rather than taken from one end of it.
      expect(pieces).toHaveLength(5);
      expect(pieces[0]).toEqual({ value: 0, color: '#ececef' });
      expect(pieces[1]).toMatchObject({ gt: 0, color: '#e9ebff' });
      expect(pieces.slice(1).map(({ color }) => color)).toEqual([
        '#e9ebff',
        '#b7c6ff',
        '#7992f5',
        '#374291',
      ]);
    });

    describe('in dark mode', () => {
      beforeEach(() => {
        getSystemColorScheme.mockReturnValue('gl-dark');
        createComponent();
      });

      afterEach(() => {
        getSystemColorScheme.mockReturnValue('gl-light');
      });

      it('reverses the ramp so a busier cell is still the brighter one', () => {
        const { pieces } = chartOptions().visualMap;

        expect(pieces.slice(1).map(({ color }) => color)).toEqual([
          '#374291',
          '#7992f5',
          '#b7c6ff',
          '#e9ebff',
        ]);
      });

      it('darkens the zero cell', () => {
        expect(chartOptions().visualMap.pieces[0].color).toBe('#3a383f');
      });

      it('darkens the cell gaps too, so they read as background', () => {
        expect(chartOptions().xAxis.splitLine.lineStyle.color).toBe('#18171d');
      });

      it('still contrasts each label against its own band', () => {
        createComponent({
          data: [
            { column: 'Chat', row: 'Power (100+)', value: 17024 },
            { column: 'Code Review', row: 'Power (100+)', value: 1 },
          ],
        });

        expect(cellWithValue(17024).label.color).toBe('#18171d');
        expect(cellWithValue(1).label.color).toBe('#fff');
      });
    });

    it('keeps the cells above the grid background and below the axes', () => {
      // The grid background paints over the series without this, which loses
      // the whole grid, and the gaps disappear under the cells.
      expect(series().z).toBe(2);
      expect(chartOptions().xAxis.z).toBe(3);
      expect(chartOptions().yAxis.z).toBe(3);
      expect(chartOptions().grid.show).toBe(true);
    });

    it('draws the cell gaps in the colour behind the grid', () => {
      expect(chartOptions().xAxis.splitLine.lineStyle).toEqual({ color: '#fff', width: 2 });
      expect(chartOptions().yAxis.splitLine.lineStyle).toEqual({ color: '#fff', width: 2 });
    });

    it('marks the zero cell out by desaturating it, not by lightening it', () => {
      // The neutral and the palest blue share a lightness, so the saturation
      // gap is the only thing separating them.
      const { pieces } = chartOptions().visualMap;
      const saturation = (hex) => {
        const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
        return Math.max(...channels) - Math.min(...channels);
      };

      expect(saturation(pieces[0].color)).toBeLessThan(8);
      pieces.slice(1).forEach((piece) => {
        expect(saturation(piece.color)).toBeGreaterThan(8);
      });
    });

    it('covers the value range with contiguous blue pieces', () => {
      const blues = chartOptions().visualMap.pieces.slice(1);

      // the topmost band is open-ended, so the largest value always lands
      expect(blues[blues.length - 1].lt).toBeUndefined();
      blues.slice(0, -1).forEach((piece, index) => {
        expect(piece.lt).toBe(blues[index + 1].gte);
      });
    });

    it('shades the smallest non-zero value blue rather than gray', () => {
      createComponent({
        data: [
          { column: 'Chat', row: 'Power (100+)', value: 1 },
          { column: 'Code Review', row: 'Power (100+)', value: 17024 },
        ],
      });

      expect(cellWithValue(1).label.color).toBe('#18171d');
      expect(chartOptions().visualMap.pieces[1]).toMatchObject({ gt: 0 });
    });

    it('anchors the bands to the smallest real value, not to one', () => {
      // A set that bottoms out well above 1 would otherwise leave the lower
      // bands unused and pile every cell into the top one.
      createComponent({
        data: [500, 800, 2000, 17024].map((value, index) => ({
          column: `c${index}`,
          row: 'r',
          value,
        })),
      });

      const [firstBlue] = chartOptions().visualMap.pieces.slice(1);
      const used = new Set(series().data.map(({ label }) => label.color));

      expect(firstBlue.lt).toBeGreaterThan(500);
      expect(used.size).toBeGreaterThan(1);
    });

    it('uses a single band when every value is identical', () => {
      createComponent({
        data: [
          { column: 'Chat', row: 'Power (100+)', value: 42 },
          { column: 'Code Review', row: 'Power (100+)', value: 42 },
        ],
      });

      expect(chartOptions().visualMap.pieces).toHaveLength(2);
    });

    it('spreads skewed values across the ramp instead of collapsing them', () => {
      // Equal-width bands would leave every small value in the lowest band.
      const skewed = [17024, 939, 355, 360, 25, 12008, 501, 202, 188, 15].map((value, index) => ({
        column: `c${index}`,
        row: 'r',
        value,
      }));
      createComponent({ data: skewed });

      const used = new Set(series().data.map(({ label }) => label.color));

      expect(used.size).toBeGreaterThan(1);
      expect(chartOptions().visualMap.pieces[1].lt).toBeLessThan(17024 / 6);
    });

    it('takes explicit band thresholds from the caller', () => {
      createComponent({ options: { bands: [10, 50, 200, 1000, 5000] } });

      const { pieces } = chartOptions().visualMap;

      // the zero piece first, then the caller's cut-offs
      expect(pieces[0]).toMatchObject({ value: 0 });
      expect(pieces.slice(1).map(({ gt, gte }) => gt ?? gte)).toEqual([0, 10, 50, 200, 1000, 5000]);
    });

    it('ignores thresholds beyond the number of hues in the ramp', () => {
      createComponent({ options: { bands: [1, 2, 3, 4, 5, 6, 7, 8] } });

      // six hues leave room for five cut-offs, plus the zero piece
      expect(chartOptions().visualMap.pieces).toHaveLength(7);
    });

    it('falls back to the zero band plus one blue when every value is zero', () => {
      createComponent({ data: [{ column: 'Chat', row: 'Power (100+)', value: 0 }] });

      const { pieces } = chartOptions().visualMap;

      expect(pieces).toHaveLength(2);
      expect(pieces[0]).toEqual({ value: 0, color: '#ececef' });
    });

    it('does not leak bands into the ECharts option', () => {
      createComponent({ options: { bands: [10, 50] } });

      expect(chartOptions().bands).toBeUndefined();
    });
  });

  it('reads the rows top-down in the order given', () => {
    // A category axis would otherwise put the first row at the bottom.
    expect(chartOptions().yAxis.data).toEqual(['Power (100+)', 'Heavy (25-99)']);
    expect(chartOptions().yAxis.inverse).toBe(true);
  });

  describe('cell labels', () => {
    it('prints the raw value in the cell by default', () => {
      expect(series().label.show).toBe(true);
      expect(series().label.formatter({ value: [0, 0, 17024] })).toBe('17024');
    });

    it('prints the value through a caller-supplied formatter', () => {
      createComponent({ options: { formatValue: (value) => `${value / 1000}K` } });

      expect(series().label.formatter({ value: [0, 0, 17000] })).toBe('17K');
    });

    it('does not leak formatValue into the ECharts option', () => {
      createComponent({ options: { formatValue: (value) => String(value) } });

      expect(chartOptions().formatValue).toBeUndefined();
    });
  });

  describe('cell contrast', () => {
    // Every stop, so no cell can end up with unreadable text.
    it.each([
      ['#ececef', '#18171d'],
      ['#e9ebff', '#18171d'],
      ['#d2dcff', '#18171d'],
      ['#b7c6ff', '#18171d'],
      ['#7992f5', '#18171d'],
      ['#4e65cd', '#fff'],
      ['#374291', '#fff'],
    ])('picks the higher-contrast label color on %s', (background, expected) => {
      expect(labelColorOn(background)).toBe(expected);
    });

    it('resolves the label color from the same pieces ECharts paints from', () => {
      // A second, independent boundary rule could drift and leave a dark label
      // on a dark cell.
      const { pieces } = chartOptions().visualMap;
      const matches = (piece, value) => {
        if (piece.value !== undefined) return value === piece.value;
        const floor = piece.gt !== undefined ? value > piece.gt : value >= piece.gte;
        return floor && (piece.lt === undefined || value < piece.lt);
      };

      series().data.forEach(({ value, label }) => {
        const painted = pieces.find((piece) => matches(piece, value[2]));

        expect(label.color).toBe(labelColorOn(painted.color));
      });
    });

    it('gives each cell a label color that contrasts with its own band', () => {
      // spans the ramp, exercising a light and a dark band
      createComponent({
        data: [
          { column: 'Chat', row: 'Power (100+)', value: 17024 },
          { column: 'Code Review', row: 'Power (100+)', value: 1 },
        ],
      });

      expect(cellWithValue(17024).label.color).toBe('#fff');
      expect(cellWithValue(1).label.color).toBe('#18171d');
    });
  });

  describe('column labels', () => {
    it('keeps every label, narrowing them as columns are added', () => {
      createComponent({
        data: Array.from({ length: 17 }, (_, index) => ({
          column: `some_long_flow_type_${index}/v1`,
          row: 'r',
          value: index + 1,
        })),
      });
      const many = chartOptions().xAxis.axisLabel;

      expect(many).toMatchObject({ interval: 0, hideOverlap: false, overflow: 'truncate' });
      expect(many.width).toBeLessThan(chartOptions().yAxis.axisLabel.width);
    });

    it('gives a handful of columns more room each', () => {
      const few = chartOptions().xAxis.axisLabel;

      expect(few.width).toBe(160);
      expect(chartOptions().grid.bottom).toBe(32);
    });

    it('never angles a label', () => {
      expect(chartOptions().xAxis.axisLabel.rotate).toBeUndefined();
    });
  });

  describe('height', () => {
    it('stretches a couple of rows to fill the space rather than leaving it blank', () => {
      // Two rows at the cell ceiling, not two rows at some fixed cell height.
      expect(wrapper.attributes('style')).toContain('min-height: 288px');
    });

    it('does not let a single row swallow the whole chart', () => {
      createComponent({ data: [{ column: 'Chat', row: 'Power (100+)', value: 1 }] });

      expect(wrapper.attributes('style')).toContain('min-height: 168px');
    });

    it('compresses rows rather than growing without bound', () => {
      createComponent({
        data: Array.from({ length: 17 }, (_, index) => ({
          column: 'Chat',
          row: `flow_type_${index}`,
          value: index + 1,
        })),
      });

      // 17 rows at the cell floor, well under 17 at the ceiling
      expect(wrapper.attributes('style')).toContain('min-height: 592px');
    });

    it('does not size itself with a percentage height', () => {
      expect(wrapper.classes()).not.toContain('gl-h-full');
    });

    it('grows into a taller panel rather than leaving it empty', () => {
      // The row count is a floor, not a fixed height.
      expect(wrapper.classes()).toContain('gl-grow');
      expect(wrapper.attributes('style')).toContain('min-height');
      expect(wrapper.attributes('style')).not.toMatch(/(^|;)\s*height:/);
    });
  });

  describe('row label gutter', () => {
    it('widens the grid to fit the longest row label', () => {
      // 'Heavy (25-99)' is 13 characters, clearing the 56px floor.
      expect(chartOptions().yAxis.axisLabel.width).toBe(91);
      expect(chartOptions().grid.left).toBe(107);
    });

    it('falls back to the minimum width for short row labels', () => {
      createComponent({ data: [{ column: 'Chat', row: 'a', value: 1 }] });

      expect(chartOptions().yAxis.axisLabel.width).toBe(56);
      expect(chartOptions().grid.left).toBe(72);
    });
  });

  it('merges caller options over the defaults', () => {
    createComponent({ options: { grid: { left: 200 } } });

    expect(chartOptions().grid.left).toBe(200);
    // a default the caller did not override still applies
    expect(chartOptions().series.label.show).toBe(true);
  });

  describe('tooltip', () => {
    it('stays hidden until a cell is hovered', () => {
      expect(findPopover().props('show')).toBe(false);
    });

    it('does not render a scoped slot before a cell has been hovered', async () => {
      // Empty bindings would make a slot that reads `value` throw.
      const consumer = shallowMountExtended(HeatMapChart, {
        propsData: { data: CELLS },
        stubs: { GlPopover: popoverStub },
        scopedSlots: { 'tooltip-content': '<span>{{ props.value.toFixed(0) }}</span>' },
      });
      const consumerChart = fakeChart();
      consumer.findComponent(GlChart).vm.$emit('created', consumerChart);

      expect(consumer.text()).toBe('');

      consumerChart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();

      expect(consumer.text()).toContain('12008');
    });

    it('names the hovered cell by its row and column', async () => {
      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();

      expect(findPopover().props('show')).toBe(true);
      expect(wrapper.text()).toContain('Heavy (25-99)');
      expect(wrapper.text()).toContain('Chat');
      expect(wrapper.text()).toContain('12008');
    });

    it('anchors itself to the hovered cell', async () => {
      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();

      expect(chart.convertToPixel).toHaveBeenCalledWith({ seriesIndex: 0 }, [0, 1]);
      expect(wrapper.find('.gl-chart-tooltip').attributes('style')).toContain('left: 120px');
    });

    it('keeps the anchor in the document so the popover has a target', () => {
      // A display:none target gives the popover no box to attach to.
      const anchor = wrapper.find('.gl-chart-tooltip');

      expect(anchor.exists()).toBe(true);
      expect(anchor.attributes('style')).not.toContain('display: none');
      expect(anchor.attributes('style')).toContain('width: 1px');
    });

    it('ignores a hover the chart cannot resolve to a pixel', async () => {
      chart.convertToPixel.mockReturnValueOnce(null);

      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });

    it('formats the hovered value through the caller-supplied formatter', async () => {
      createComponent({ options: { formatValue: (value) => `${value} sessions` } });

      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();

      expect(wrapper.text()).toContain('12008 sessions');
    });

    it('hides again when the pointer leaves the cell', async () => {
      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();
      chart.trigger('mouseout');
      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });

    it('keeps its position and contents while hiding', async () => {
      // Clearing them sends the popover to the corner before it fades.
      chart.trigger('mouseover', { value: [0, 1, 12008] });
      await nextTick();
      const anchoredAt = wrapper.find('.gl-chart-tooltip').attributes('style');

      chart.trigger('mouseout');
      await nextTick();

      expect(wrapper.find('.gl-chart-tooltip').attributes('style')).toBe(anchoredAt);
      expect(wrapper.text()).toContain('Heavy (25-99)');
    });

    it("scopes its hover handlers to this chart's own series", () => {
      // Otherwise anything a caller merges in through `options` drives the
      // tooltip too, with a value shape that is not a cell.
      expect(chart.queryFor('mouseover')).toEqual({ seriesIndex: 0 });
      expect(chart.queryFor('mouseout')).toEqual({ seriesIndex: 0 });
    });

    it.each([
      ['a string', 'not-a-cell'],
      ['a number', 7],
      ['nothing', undefined],
    ])('ignores a hover carrying %s instead of a cell', async (_name, value) => {
      chart.trigger('mouseover', { value });
      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });

    it('ignores a hover event that carries no cell value', async () => {
      chart.trigger('mouseover', {});
      await nextTick();

      expect(findPopover().props('show')).toBe(false);
    });
  });

  // The specs above stub GlChart, so ECharts never runs and a malformed
  // option would go unnoticed.
  describe('with a real ECharts instance', () => {
    it.each([
      ['populated', CELLS],
      ['empty', []],
      ['single cell', [{ column: 'Chat', row: 'Power (100+)', value: 1 }]],
      ['all zero', [{ column: 'Chat', row: 'Power (100+)', value: 0 }]],
    ])('renders %s data without throwing', async (_name, data) => {
      // ECharts needs an attached element, and GlChart initializes a tick
      // after mount.
      const mounted = mountExtended(HeatMapChart, {
        propsData: { data },
        attachTo: document.body,
      });
      await waitForPromises();

      expect(mounted.findByTestId('heat-map-chart').exists()).toBe(true);
    });
  });

  it('detaches its chart listeners on destroy', () => {
    wrapper.destroy();

    expect(chart.off).toHaveBeenCalledWith('mouseover', expect.any(Function));
    expect(chart.off).toHaveBeenCalledWith('mouseout', expect.any(Function));
  });
});
