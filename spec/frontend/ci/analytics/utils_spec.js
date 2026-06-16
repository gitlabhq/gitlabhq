import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  calculatePipelineCountPercentage,
  calculateRateDenominator,
  formatPipelineCountPercentage,
  formatPipelineDuration,
  formatPipelineDurationForAxis,
} from '~/ci/analytics/utils';

const largeNumber = '12345678901234567890'; // Larger than MAX_SAFE_INTEGER

describe('Stats formatting utilities', () => {
  let captureExceptionSpy;

  beforeEach(() => {
    captureExceptionSpy = jest.spyOn(Sentry, 'captureException').mockImplementation(() => {});
  });

  afterEach(() => {
    captureExceptionSpy.mockRestore();
  });

  describe('calculatePipelineCountPercentage', () => {
    it.each`
      input                                | output
      ${['0', '100']}                      | ${0}
      ${['33', '100']}                     | ${33}
      ${['50', '100']}                     | ${50}
      ${['66', '100']}                     | ${66}
      ${['99', '100']}                     | ${99}
      ${['10', '0']}                       | ${undefined}
      ${[largeNumber, largeNumber]}        | ${100}
      ${[largeNumber, `${largeNumber}00`]} | ${1}
      ${['not-a-number', '1000']}          | ${undefined}
      ${['50', 'not-a-number']}            | ${undefined}
      ${[null, '100']}                     | ${undefined}
      ${['50', null]}                      | ${undefined}
    `('formats $input.0 / $input.1 to "$output"', ({ input, output }) => {
      const [a, b] = input;
      expect(calculatePipelineCountPercentage(a, b)).toBe(output);
    });

    it.each`
      input              | output
      ${['666', '1000']} | ${66.60000000000001}
      ${['888', '1000']} | ${88.8}
      ${['999', '1000']} | ${99.9}
    `('formats by rounding $input.0 / $input.1 to "$output"', ({ input, output }) => {
      const [a, b] = input;
      expect(calculatePipelineCountPercentage(a, b)).toBe(output);
    });

    it.each`
      input
      ${['not-a-number', '1000']}
      ${['50', 'not-a-number']}
      ${[null, '100']}
      ${['50', null]}
    `('reports the parse error to Sentry for input $input', ({ input }) => {
      const [a, b] = input;

      calculatePipelineCountPercentage(a, b);

      expect(captureExceptionSpy).toHaveBeenCalledTimes(1);
    });

    it('does not report to Sentry for valid input', () => {
      calculatePipelineCountPercentage('50', '100');

      expect(captureExceptionSpy).not.toHaveBeenCalled();
    });
  });

  describe('formatPipelineCountPercentage', () => {
    it.each`
      input                                | output
      ${['0', '100']}                      | ${'0%'}
      ${['33', '100']}                     | ${'33%'}
      ${['50', '100']}                     | ${'50%'}
      ${['66', '100']}                     | ${'66%'}
      ${['99', '100']}                     | ${'99%'}
      ${['10', '0']}                       | ${'-'}
      ${[largeNumber, largeNumber]}        | ${'100%'}
      ${[largeNumber, `${largeNumber}00`]} | ${'1%'}
      ${['not-a-number', '1000']}          | ${'-'}
      ${['50', 'not-a-number']}            | ${'-'}
      ${[null, '100']}                     | ${'-'}
      ${['50', null]}                      | ${'-'}
    `('formats $input.0 / $input.1 to "$output"', ({ input, output }) => {
      const [a, b] = input;
      expect(formatPipelineCountPercentage(a, b)).toBe(output);
    });

    it.each`
      input              | output
      ${['666', '1000']} | ${'67%'}
      ${['888', '1000']} | ${'89%'}
      ${['999', '1000']} | ${'100%'}
    `('formats by rounding $input.0 / $input.1 to "$output"', ({ input, output }) => {
      const [a, b] = input;
      expect(formatPipelineCountPercentage(a, b)).toBe(output);
    });
  });

  describe('calculateRateDenominator', () => {
    it.each`
      successCount | failedCount  | expected
      ${'3'}       | ${'7'}       | ${'10'}
      ${'0'}       | ${'0'}       | ${'0'}
      ${'100'}     | ${'0'}       | ${'100'}
      ${null}      | ${'5'}       | ${'5'}
      ${'5'}       | ${null}      | ${'5'}
      ${null}      | ${null}      | ${'0'}
      ${undefined} | ${undefined} | ${'0'}
    `(
      'returns "$expected" when successCount=$successCount, failedCount=$failedCount',
      ({ successCount, failedCount, expected }) => {
        expect(calculateRateDenominator(successCount, failedCount)).toBe(expected);
        expect(captureExceptionSpy).not.toHaveBeenCalled();
      },
    );

    it('handles BigInt-safe large numbers', () => {
      const large = '12345678901234567890';
      expect(calculateRateDenominator(large, large)).toBe('24691357802469135780');
    });

    describe('when inputs cannot be parsed as BigInt', () => {
      it('returns the fallback value', () => {
        expect(calculateRateDenominator('not-a-number', '1', '99')).toBe('99');
      });

      it('returns null when no fallback is provided', () => {
        expect(calculateRateDenominator('not-a-number', '1')).toBe(null);
      });

      it('reports the error to Sentry', () => {
        calculateRateDenominator('not-a-number', '1', '99');
        expect(captureExceptionSpy).toHaveBeenCalledTimes(1);
        expect(captureExceptionSpy.mock.calls[0][0]).toBeInstanceOf(SyntaxError);
      });
    });
  });

  describe('formatPipelineDuration', () => {
    const tenMinutes = 60 * 10;
    const oneDay = 24 * 60 * 60;

    it.each`
      input                  | output
      ${tenMinutes}          | ${'10m'}
      ${oneDay}              | ${'1d'}
      ${oneDay + tenMinutes} | ${'1d 10m'}
      ${0}                   | ${'0m'}
      ${NaN}                 | ${'-'}
      ${'60000'}             | ${'-'}
      ${null}                | ${'-'}
      ${undefined}           | ${'-'}
      ${{}}                  | ${'-'}
    `('formats $input to "$output"', ({ input, output }) => {
      expect(formatPipelineDuration(input)).toBe(output);
    });
  });

  describe('formatPipelineDurationForAxis', () => {
    it.each`
      input             | output
      ${1}              | ${'0.02'}
      ${60 * 10}        | ${'10'}
      ${3600}           | ${'60'}
      ${60 * 10 ** 3}   | ${'1k'}
      ${3600 * 10 ** 4} | ${'600k'}
      ${0}              | ${'0'}
      ${NaN}            | ${'-'}
      ${'60000'}        | ${'-'}
    `('formats $input to "$output"', ({ input, output }) => {
      expect(formatPipelineDurationForAxis(input)).toBe(output);
    });
  });
});
