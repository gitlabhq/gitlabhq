import { barCategoryAxisOptions } from '~/glql/components/presenters/bar_chart/bar_chart_options';

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

  it('falls back to the minimum width for an empty label list', () => {
    expect(barCategoryAxisOptions([]).yAxis.axisLabel.width).toBe(49);
  });
});
