import { SUPPORTED_FORMATS } from '~/lib/utils/unit_format';
import {
  getYAxisOptions,
  getTooltipFormatter,
  getValidThresholds,
} from '~/monitoring/components/charts/options';

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

  describe('getValidThresholds', () => {
    const invalidCases = [null, undefined, NaN, 'a string', true, false];

    let thresholds;

    afterEach(() => {
      thresholds = null;
    });

    it('returns same thresholds when passed values within range', () => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [10, 50],
      });

      expect(thresholds).toEqual([10, 50]);
    });

    it('filters out thresholds that are out of range', () => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [-5, 10, 110],
      });

      expect(thresholds).toEqual([10]);
    });
    it('filters out duplicate thresholds', () => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [5, 5, 10, 10],
      });

      expect(thresholds).toEqual([5, 10]);
    });

    it('sorts passed thresholds and applies only the first two in ascending order', () => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [10, 1, 35, 20, 5],
      });

      expect(thresholds).toEqual([1, 5]);
    });

    it('thresholds equal to min or max are filtered out', () => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [0, 100],
      });

      expect(thresholds).toEqual([]);
    });

    it.each(invalidCases)('invalid values for thresholds are filtered out', (invalidValue) => {
      thresholds = getValidThresholds({
        mode: 'absolute',
        range: { min: 0, max: 100 },
        values: [10, invalidValue],
      });

      expect(thresholds).toEqual([10]);
    });

    describe('range', () => {
      it('when range is not defined, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          values: [10, 20],
        });

        expect(thresholds).toEqual([]);
      });

      it('when min is not defined, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          range: { max: 100 },
          values: [10, 20],
        });

        expect(thresholds).toEqual([]);
      });

      it('when max is not defined, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          range: { min: 0 },
          values: [10, 20],
        });

        expect(thresholds).toEqual([]);
      });

      it('when min is larger than max, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          range: { min: 100, max: 0 },
          values: [10, 20],
        });

        expect(thresholds).toEqual([]);
      });

      it.each(invalidCases)(
        'when min has invalid value, empty result is returned',
        (invalidValue) => {
          thresholds = getValidThresholds({
            mode: 'absolute',
            range: { min: invalidValue, max: 100 },
            values: [10, 20],
          });

          expect(thresholds).toEqual([]);
        },
      );

      it.each(invalidCases)(
        'when max has invalid value, empty result is returned',
        (invalidValue) => {
          thresholds = getValidThresholds({
            mode: 'absolute',
            range: { min: 0, max: invalidValue },
            values: [10, 20],
          });

          expect(thresholds).toEqual([]);
        },
      );
    });

    describe('values', () => {
      it('if values parameter is omitted, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          range: { min: 0, max: 100 },
        });

        expect(thresholds).toEqual([]);
      });

      it('if there are no values passed, empty result is returned', () => {
        thresholds = getValidThresholds({
          mode: 'absolute',
          range: { min: 0, max: 100 },
          values: [],
        });

        expect(thresholds).toEqual([]);
      });

      it.each(invalidCases)(
        'if invalid values are passed, empty result is returned',
        (invalidValue) => {
          thresholds = getValidThresholds({
            mode: 'absolute',
            range: { min: 0, max: 100 },
            values: [invalidValue],
          });

          expect(thresholds).toEqual([]);
        },
      );
    });

    describe('mode', () => {
      it.each(invalidCases)(
        'if invalid values are passed, empty result is returned',
        (invalidValue) => {
          thresholds = getValidThresholds({
            mode: invalidValue,
            range: { min: 0, max: 100 },
            values: [10, 50],
          });

          expect(thresholds).toEqual([]);
        },
      );

      it('if mode is not passed, empty result is returned', () => {
        thresholds = getValidThresholds({
          range: { min: 0, max: 100 },
          values: [10, 50],
        });

        expect(thresholds).toEqual([]);
      });

      describe('absolute mode', () => {
        it('absolute mode behaves correctly', () => {
          thresholds = getValidThresholds({
            mode: 'absolute',
            range: { min: 0, max: 100 },
            values: [10, 50],
          });

          expect(thresholds).toEqual([10, 50]);
        });
      });

      describe('percentage mode', () => {
        it('percentage mode behaves correctly', () => {
          thresholds = getValidThresholds({
            mode: 'percentage',
            range: { min: 0, max: 1000 },
            values: [10, 50],
          });

          expect(thresholds).toEqual([100, 500]);
        });

        const outOfPercentBoundsValues = [-1, 0, 100, 101];
        it.each(outOfPercentBoundsValues)(
          'when values out of 0-100 range are passed, empty result is returned',
          (invalidValue) => {
            thresholds = getValidThresholds({
              mode: 'percentage',
              range: { min: 0, max: 1000 },
              values: [invalidValue],
            });

            expect(thresholds).toEqual([]);
          },
        );
      });
    });

    it('calling without passing object parameter returns empty array', () => {
      thresholds = getValidThresholds();

      expect(thresholds).toEqual([]);
    });
  });
});
