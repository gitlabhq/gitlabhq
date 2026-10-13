import { GL_COLOR_NEUTRAL_0, GL_COLOR_NEUTRAL_800 } from '@gitlab/ui/src/tokens/build/js/tokens';
import { getColorContrast } from '@gitlab/ui/src/utils/utils';
import {
  CATEGORY_SHADES_DARK,
  CATEGORY_SHADES_LIGHT,
  barCategoryAxisOptions,
  barChartHeightFor,
  categoryShadeFor,
  colorSeriesByCategory,
  shareLabelFormatter,
} from '~/glql/components/presenters/bar_chart/bar_chart_options';

// Most prominent first, as the real ramps are; names rather than hexes so a
// failure reads as a position rather than a colour.
const SHADES = ['first', 'second', 'third', 'fourth', 'fifth'];

describe('barCategoryAxisOptions', () => {
  it('returns only yAxis and grid keys, so callers can spread it alongside xAxis options', () => {
    expect(Object.keys(barCategoryAxisOptions(['ruby']))).toEqual(['yAxis', 'grid']);
  });

  it('passes labels through unchanged, ellipsizing by pixel width instead', () => {
    const { yAxis } = barCategoryAxisOptions(['Jan 1, 2026']);

    expect(yAxis.axisLabel.formatter('Jan 1, 2026')).toBe('Jan 1, 2026');
    expect(yAxis.axisLabel.overflow).toBe('truncate');
  });

  it('clamps short labels to the minimum width', () => {
    const options = barCategoryAxisOptions(['ruby', 'python']);

    expect(options.yAxis.axisLabel.width).toBe(49);
    expect(options.yAxis.nameGap).toBe(65);
    expect(options.grid.left).toBe(85);
  });

  it('sizes the label gutter from the longest label', () => {
    const options = barCategoryAxisOptions(['ruby', 'Jan 1, 2026']);

    expect(options.yAxis.axisLabel.width).toBe(77);
    expect(options.yAxis.nameGap).toBe(93);
    expect(options.grid.left).toBe(113);
  });

  it('clamps very long labels to the maximum width', () => {
    const options = barCategoryAxisOptions(['x'.repeat(40)]);

    expect(options.yAxis.axisLabel.width).toBe(160);
    expect(options.yAxis.nameGap).toBe(176);
    expect(options.grid.left).toBe(196);
  });

  it('fits a share label in full only when shareLabels is set', () => {
    const label = 'Returning · 1,555 · 78%';

    expect(barCategoryAxisOptions([label]).yAxis.axisLabel.width).toBe(160);
    expect(barCategoryAxisOptions([label], { shareLabels: true }).yAxis.axisLabel.width).toBe(
      label.length * 7,
    );
  });

  it('clamps very long share labels to the wider maximum width', () => {
    const options = barCategoryAxisOptions(['x'.repeat(40)], { shareLabels: true });

    expect(options.yAxis.axisLabel.width).toBe(240);
    expect(options.yAxis.nameGap).toBe(256);
    expect(options.grid.left).toBe(276);
  });

  it('falls back to the minimum width for an empty label list', () => {
    expect(barCategoryAxisOptions([]).yAxis.axisLabel.width).toBe(49);
  });

  it('drops the axis title space from the grid when there is no axis title', () => {
    const options = barCategoryAxisOptions(['ruby'], { axisTitle: false });

    expect(options.yAxis.nameGap).toBe(65);
    expect(options.grid).toEqual({ left: 65, bottom: 28 });
  });

  it('leaves the bottom padding to GlBarChart when there is an axis title', () => {
    expect(barCategoryAxisOptions(['ruby']).grid).toEqual({ left: 85 });
  });
});

describe('barChartHeightFor', () => {
  it('grows by one row band per category on top of the grid padding', () => {
    expect(barChartHeightFor(2)).toBe(156);
    expect(barChartHeightFor(3)).toBe(204);
  });

  it('reserves less bottom padding without an axis title', () => {
    expect(barChartHeightFor(2, { axisTitle: false })).toBe(140);
  });

  it('adds half a band per extra tiled bar', () => {
    expect(barChartHeightFor(2, { barsPerRow: 2 })).toBe(204);
    expect(barChartHeightFor(2, { barsPerRow: 3 })).toBe(252);
  });

  it('never shrinks below one row', () => {
    expect(barChartHeightFor(0)).toBe(barChartHeightFor(1));
  });

  it('caps at the default chart height for many rows', () => {
    expect(barChartHeightFor(20)).toBe(400);
  });
});

describe('category shade ramps', () => {
  const WCAG_GRAPHICAL_OBJECT_MIN_CONTRAST = 3;

  // The data colour tokens have the same hex in both modes, so each ramp is
  // checked against its own mode's `--gl-background-color-section`.
  it.each`
    mode       | shades                   | background
    ${'light'} | ${CATEGORY_SHADES_LIGHT} | ${GL_COLOR_NEUTRAL_0}
    ${'dark'}  | ${CATEGORY_SHADES_DARK}  | ${GL_COLOR_NEUTRAL_800}
  `('clears the graphical object contrast minimum in $mode mode', ({ shades, background }) => {
    const scores = shades.map((shade) => Number(getColorContrast(shade, background).score));

    expect(scores).toHaveLength(5);
    scores.forEach((score) => {
      expect(score).toBeGreaterThanOrEqual(WCAG_GRAPHICAL_OBJECT_MIN_CONTRAST);
    });
  });

  it('runs darkest first in light mode and lightest first in dark mode', () => {
    expect(CATEGORY_SHADES_LIGHT[0]).toBe('#303470');
    expect(CATEGORY_SHADES_DARK[0]).toBe('#e9ebff');
  });
});

describe('categoryShadeFor', () => {
  it('gives the two ends of the scale to two categories', () => {
    expect(categoryShadeFor(0, 2, SHADES)).toBe('first');
    expect(categoryShadeFor(1, 2, SHADES)).toBe('fifth');
  });

  it('spreads more categories evenly across the scale', () => {
    expect([0, 1, 2].map((i) => categoryShadeFor(i, 3, SHADES))).toEqual([
      'first',
      'third',
      'fifth',
    ]);
  });

  it('uses the most prominent shade for a single category', () => {
    expect(categoryShadeFor(0, 1, SHADES)).toBe('first');
  });

  it('cycles through the scale when there are more categories than shades', () => {
    expect(categoryShadeFor(5, 7, SHADES)).toBe('first');
    expect(categoryShadeFor(6, 7, SHADES)).toBe('second');
  });
});

describe('colorSeriesByCategory', () => {
  const styled = (color) => ({
    itemStyle: { color, borderColor: color },
    emphasis: { itemStyle: { color, borderColor: color } },
  });

  it('wraps each point with its own fill and border colour, most prominent on the last row', () => {
    // ECharts draws the first row at the bottom, so the last point is the top row.
    expect(
      colorSeriesByCategory(
        {
          'Total count': [
            [21, 'ruby'],
            [14, 'python'],
          ],
        },
        SHADES,
      ),
    ).toEqual({
      'Total count': [
        { value: [21, 'ruby'], ...styled('fifth') },
        { value: [14, 'python'], ...styled('first') },
      ],
    });
  });

  it('spreads the shades across the rows of each series', () => {
    const [top, middle, bottom] = colorSeriesByCategory(
      {
        s: [
          [1, 'a'],
          [2, 'b'],
          [3, 'c'],
        ],
      },
      SHADES,
    ).s.map((point) => point.itemStyle.color);

    expect([bottom, middle, top]).toEqual(['first', 'third', 'fifth']);
  });

  it('returns an empty object for no series', () => {
    expect(colorSeriesByCategory({}, SHADES)).toEqual({});
  });
});

describe('shareLabelFormatter', () => {
  const POINTS = [
    [21, 'ruby'],
    [14, 'python'],
  ];

  it('appends the value and its share of the total to the label', () => {
    const format = shareLabelFormatter(POINTS);

    expect(format('ruby')).toBe('ruby · 21 · 60%');
    expect(format('python')).toBe('python · 14 · 40%');
  });

  it('formats the count with thousands separators and the share to one decimal', () => {
    const format = shareLabelFormatter([
      [1555, 'a'],
      [500, 'b'],
    ]);

    expect(format('a')).toBe('a · 1,555 · 75.7%');
  });

  it('formats the label and the value with the given formatters', () => {
    const format = shareLabelFormatter(POINTS, {
      formatLabel: (label) => label.toUpperCase(),
      formatValue: (value) => `${value} items`,
    });

    expect(format('ruby')).toBe('RUBY · 21 items · 60%');
  });

  it('shows zero for a category that is not in the points', () => {
    expect(shareLabelFormatter(POINTS)('go')).toBe('go · 0 · 0%');
  });

  it('shows a zero share when the total is zero', () => {
    expect(shareLabelFormatter([[0, 'ruby']])('ruby')).toBe('ruby · 0 · 0%');
  });
});
