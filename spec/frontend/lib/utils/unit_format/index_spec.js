import { getFormatter, SUPPORTED_FORMATS } from '~/lib/utils/unit_format';

describe('unit_format', () => {
  describe('when a supported format is provided, the returned function formats', () => {
    it('numbers, by default', () => {
      expect(getFormatter()(1)).toEqual('1');
    });

    it('numbers', () => {
      const formatNumber = getFormatter(SUPPORTED_FORMATS.number);

      expect(formatNumber(1)).toEqual('1');
      expect(formatNumber(100)).toEqual('100');
      expect(formatNumber(1000)).toEqual('1,000');
      expect(formatNumber(10000)).toEqual('10,000');
      expect(formatNumber(1000000)).toEqual('1,000,000');
    });

    it('percent', () => {
      const formatPercent = getFormatter(SUPPORTED_FORMATS.percent);

      expect(formatPercent(1)).toEqual('100%');
      expect(formatPercent(1, 2)).toEqual('100.00%');

      expect(formatPercent(0.1)).toEqual('10%');
      expect(formatPercent(0.5)).toEqual('50%');

      expect(formatPercent(0.888888)).toEqual('89%');
      expect(formatPercent(0.888888, 2)).toEqual('88.89%');
      expect(formatPercent(0.888888, 5)).toEqual('88.88880%');

      expect(formatPercent(2)).toEqual('200%');
      expect(formatPercent(10)).toEqual('1,000%');
    });

    it('percentunit', () => {
      const formatPercentHundred = getFormatter(SUPPORTED_FORMATS.percentHundred);

      expect(formatPercentHundred(1)).toEqual('1%');
      expect(formatPercentHundred(1, 2)).toEqual('1.00%');

      expect(formatPercentHundred(88.8888)).toEqual('89%');
      expect(formatPercentHundred(88.8888, 2)).toEqual('88.89%');
      expect(formatPercentHundred(88.8888, 5)).toEqual('88.88880%');

      expect(formatPercentHundred(100)).toEqual('100%');
      expect(formatPercentHundred(100, 2)).toEqual('100.00%');

      expect(formatPercentHundred(200)).toEqual('200%');
      expect(formatPercentHundred(1000)).toEqual('1,000%');
    });

    it('seconds', () => {
      expect(getFormatter(SUPPORTED_FORMATS.seconds)(1)).toEqual('1s');
    });

    it('miliseconds', () => {
      const formatMiliseconds = getFormatter(SUPPORTED_FORMATS.miliseconds);

      expect(formatMiliseconds(1)).toEqual('1ms');
      expect(formatMiliseconds(100)).toEqual('100ms');
      expect(formatMiliseconds(1000)).toEqual('1,000ms');
      expect(formatMiliseconds(10000)).toEqual('10,000ms');
      expect(formatMiliseconds(1000000)).toEqual('1,000,000ms');
    });

    it('bytes', () => {
      const formatBytes = getFormatter(SUPPORTED_FORMATS.bytes);

      expect(formatBytes(1)).toEqual('1B');
      expect(formatBytes(1, 1)).toEqual('1.0B');

      expect(formatBytes(10)).toEqual('10B');
      expect(formatBytes(10 ** 2)).toEqual('100B');
      expect(formatBytes(10 ** 3)).toEqual('1kB');
      expect(formatBytes(10 ** 4)).toEqual('10kB');
      expect(formatBytes(10 ** 5)).toEqual('100kB');
      expect(formatBytes(10 ** 6)).toEqual('1MB');
      expect(formatBytes(10 ** 7)).toEqual('10MB');
      expect(formatBytes(10 ** 8)).toEqual('100MB');
      expect(formatBytes(10 ** 9)).toEqual('1GB');
      expect(formatBytes(10 ** 10)).toEqual('10GB');
      expect(formatBytes(10 ** 11)).toEqual('100GB');
    });

    it('kilobytes', () => {
      expect(getFormatter(SUPPORTED_FORMATS.kilobytes)(1)).toEqual('1kB');
      expect(getFormatter(SUPPORTED_FORMATS.kilobytes)(1, 1)).toEqual('1.0kB');
    });

    it('megabytes', () => {
      expect(getFormatter(SUPPORTED_FORMATS.megabytes)(1)).toEqual('1MB');
      expect(getFormatter(SUPPORTED_FORMATS.megabytes)(1, 1)).toEqual('1.0MB');
    });

    it('gigabytes', () => {
      expect(getFormatter(SUPPORTED_FORMATS.gigabytes)(1)).toEqual('1GB');
      expect(getFormatter(SUPPORTED_FORMATS.gigabytes)(1, 1)).toEqual('1.0GB');
    });

    it('terabytes', () => {
      expect(getFormatter(SUPPORTED_FORMATS.terabytes)(1)).toEqual('1TB');
      expect(getFormatter(SUPPORTED_FORMATS.terabytes)(1, 1)).toEqual('1.0TB');
    });

    it('petabytes', () => {
      expect(getFormatter(SUPPORTED_FORMATS.petabytes)(1)).toEqual('1PB');
      expect(getFormatter(SUPPORTED_FORMATS.petabytes)(1, 1)).toEqual('1.0PB');
    });
  });

  describe('when get formatter format is incorrect', () => {
    it('formatter fails', () => {
      expect(() => getFormatter('not-supported')(1)).toThrow();
    });
  });
});
