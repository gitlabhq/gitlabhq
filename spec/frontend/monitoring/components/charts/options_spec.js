import { SUPPORTED_FORMATS } from '~/lib/utils/unit_format';
import { getYAxisOptions, getTooltipFormatter } from '~/monitoring/components/charts/options';

describe('options spec', () => {
  describe('getYAxisOptions', () => {
    it('default options', () => {
      const options = getYAxisOptions();

      expect(options).toMatchObject({
        name: expect.any(String),
        axisLabel: {
          formatter: expect.any(Function),
        },
        scale: true,
        boundaryGap: [expect.any(Number), expect.any(Number)],
      });

      expect(options.name).not.toHaveLength(0);
    });

    it('name options', () => {
      const yAxisName = 'My axis values';
      const options = getYAxisOptions({
        name: yAxisName,
      });

      expect(options).toMatchObject({
        name: yAxisName,
        nameLocation: 'center',
        nameGap: expect.any(Number),
      });
    });

    it('formatter options defaults to engineering notation', () => {
      const options = getYAxisOptions();

      expect(options.axisLabel.formatter).toEqual(expect.any(Function));
      expect(options.axisLabel.formatter(3002.1)).toBe('3k');
    });

    it('formatter options allows for precision to be set explicitly', () => {
      const options = getYAxisOptions({
        precision: 4,
      });

      expect(options.axisLabel.formatter).toEqual(expect.any(Function));
      expect(options.axisLabel.formatter(5002.1)).toBe('5.0021k');
    });

    it('formatter options allows for overrides in milliseconds', () => {
      const options = getYAxisOptions({
        format: SUPPORTED_FORMATS.milliseconds,
      });

      expect(options.axisLabel.formatter).toEqual(expect.any(Function));
      expect(options.axisLabel.formatter(1.1234)).toBe('1.12ms');
    });

    it('formatter options allows for overrides in bytes', () => {
      const options = getYAxisOptions({
        format: SUPPORTED_FORMATS.bytes,
      });

      expect(options.axisLabel.formatter).toEqual(expect.any(Function));
      expect(options.axisLabel.formatter(1)).toBe('1.00B');
    });
  });

  describe('getTooltipFormatter', () => {
    it('default format', () => {
      const formatter = getTooltipFormatter();

      expect(formatter).toEqual(expect.any(Function));
      expect(formatter(0.11111)).toBe('111.1m');
    });

    it('defined format', () => {
      const formatter = getTooltipFormatter({
        format: SUPPORTED_FORMATS.bytes,
      });

      expect(formatter(1)).toBe('1.000B');
    });
  });
});
