import {
  number,
  percent,
  percentHundred,
  seconds,
  milliseconds,
  decimalBytes,
  kilobytes,
  megabytes,
  gigabytes,
  terabytes,
  petabytes,
  bytes,
  kibibytes,
  mebibytes,
  gibibytes,
  tebibytes,
  pebibytes,
  engineering,
  getFormatter,
  SUPPORTED_FORMATS,
} from '~/lib/utils/unit_format';

describe('unit_format', () => {
  it('engineering', () => {
    expect(engineering(1)).toBe('1');
    expect(engineering(100)).toBe('100');
    expect(engineering(1000)).toBe('1k');
    expect(engineering(10_000)).toBe('10k');
    expect(engineering(1_000_000)).toBe('1M');

    expect(engineering(10 ** 9)).toBe('1G');
  });

  it('number', () => {
    expect(number(1)).toBe('1');
    expect(number(100)).toBe('100');
    expect(number(1000)).toBe('1,000');
    expect(number(10_000)).toBe('10,000');
    expect(number(1_000_000)).toBe('1,000,000');

    expect(number(10 ** 9)).toBe('1,000,000,000');
  });

  it('percent', () => {
    expect(percent(1)).toBe('100%');
    expect(percent(1, 2)).toBe('100.00%');

    expect(percent(0.1)).toBe('10%');
    expect(percent(0.5)).toBe('50%');

    expect(percent(0.888888)).toBe('89%');
    expect(percent(0.888888, 2)).toBe('88.89%');
    expect(percent(0.888888, 5)).toBe('88.88880%');

    expect(percent(2)).toBe('200%');
    expect(percent(10)).toBe('1,000%');
  });

  it('percentHundred', () => {
    expect(percentHundred(1)).toBe('1%');
    expect(percentHundred(1, 2)).toBe('1.00%');

    expect(percentHundred(88.8888)).toBe('89%');
    expect(percentHundred(88.8888, 2)).toBe('88.89%');
    expect(percentHundred(88.8888, 5)).toBe('88.88880%');

    expect(percentHundred(100)).toBe('100%');
    expect(percentHundred(100, 2)).toBe('100.00%');

    expect(percentHundred(200)).toBe('200%');
    expect(percentHundred(1000)).toBe('1,000%');
  });

  it('seconds', () => {
    expect(seconds(1)).toBe('1s');
  });

  it('milliseconds', () => {
    expect(milliseconds(1)).toBe('1ms');
    expect(milliseconds(100)).toBe('100ms');
    expect(milliseconds(1000)).toBe('1,000ms');
    expect(milliseconds(10_000)).toBe('10,000ms');
    expect(milliseconds(1_000_000)).toBe('1,000,000ms');
  });

  it('decimalBytes', () => {
    expect(decimalBytes(1)).toBe('1B');
    expect(decimalBytes(1, 1)).toBe('1.0B');

    expect(decimalBytes(10)).toBe('10B');
    expect(decimalBytes(10 ** 2)).toBe('100B');
    expect(decimalBytes(10 ** 3)).toBe('1kB');
    expect(decimalBytes(10 ** 4)).toBe('10kB');
    expect(decimalBytes(10 ** 5)).toBe('100kB');
    expect(decimalBytes(10 ** 6)).toBe('1MB');
    expect(decimalBytes(10 ** 7)).toBe('10MB');
    expect(decimalBytes(10 ** 8)).toBe('100MB');
    expect(decimalBytes(10 ** 9)).toBe('1GB');
    expect(decimalBytes(10 ** 10)).toBe('10GB');
    expect(decimalBytes(10 ** 11)).toBe('100GB');
  });

  it('kilobytes', () => {
    expect(kilobytes(1)).toBe('1kB');
    expect(kilobytes(1, 1)).toBe('1.0kB');
  });

  it('megabytes', () => {
    expect(megabytes(1)).toBe('1MB');
    expect(megabytes(1, 1)).toBe('1.0MB');
  });

  it('gigabytes', () => {
    expect(gigabytes(1)).toBe('1GB');
    expect(gigabytes(1, 1)).toBe('1.0GB');
  });

  it('terabytes', () => {
    expect(terabytes(1)).toBe('1TB');
    expect(terabytes(1, 1)).toBe('1.0TB');
  });

  it('petabytes', () => {
    expect(petabytes(1)).toBe('1PB');
    expect(petabytes(1, 1)).toBe('1.0PB');
  });

  it('bytes', () => {
    expect(bytes(1)).toBe('1B');
    expect(bytes(1, 1)).toBe('1.0B');

    expect(bytes(10)).toBe('10B');
    expect(bytes(100)).toBe('100B');
    expect(bytes(1000)).toBe('1,000B');

    expect(bytes(1 * 1024)).toBe('1KiB');
    expect(bytes(1 * 1024 ** 2)).toBe('1MiB');
    expect(bytes(1 * 1024 ** 3)).toBe('1GiB');
  });

  it('kibibytes', () => {
    expect(kibibytes(1)).toBe('1KiB');
    expect(kibibytes(1, 1)).toBe('1.0KiB');
  });

  it('mebibytes', () => {
    expect(mebibytes(1)).toBe('1MiB');
    expect(mebibytes(1, 1)).toBe('1.0MiB');
  });

  it('gibibytes', () => {
    expect(gibibytes(1)).toBe('1GiB');
    expect(gibibytes(1, 1)).toBe('1.0GiB');
  });

  it('tebibytes', () => {
    expect(tebibytes(1)).toBe('1TiB');
    expect(tebibytes(1, 1)).toBe('1.0TiB');
  });

  it('pebibytes', () => {
    expect(pebibytes(1)).toBe('1PiB');
    expect(pebibytes(1, 1)).toBe('1.0PiB');
  });

  describe('getFormatter', () => {
    it.each([
      [1],
      [10],
      [200],
      [100],
      [1000],
      [10_000],
      [100_000],
      [1_000_000],
      [10 ** 6],
      [10 ** 9],
      [0.1],
      [0.5],
      [0.888888],
    ])('formatting functions yield the same result as getFormatter for %d', (value) => {
      expect(number(value)).toBe(getFormatter(SUPPORTED_FORMATS.number)(value));
      expect(percent(value)).toBe(getFormatter(SUPPORTED_FORMATS.percent)(value));
      expect(percentHundred(value)).toBe(getFormatter(SUPPORTED_FORMATS.percentHundred)(value));

      expect(seconds(value)).toBe(getFormatter(SUPPORTED_FORMATS.seconds)(value));
      expect(milliseconds(value)).toBe(getFormatter(SUPPORTED_FORMATS.milliseconds)(value));

      expect(decimalBytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.decimalBytes)(value));
      expect(kilobytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.kilobytes)(value));
      expect(megabytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.megabytes)(value));
      expect(gigabytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.gigabytes)(value));
      expect(terabytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.terabytes)(value));
      expect(petabytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.petabytes)(value));

      expect(bytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.bytes)(value));
      expect(kibibytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.kibibytes)(value));
      expect(mebibytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.mebibytes)(value));
      expect(gibibytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.gibibytes)(value));
      expect(tebibytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.tebibytes)(value));
      expect(pebibytes(value)).toBe(getFormatter(SUPPORTED_FORMATS.pebibytes)(value));

      expect(engineering(value)).toBe(getFormatter(SUPPORTED_FORMATS.engineering)(value));
    });

    describe('when get formatter format is incorrect', () => {
      it('formatter fails', () => {
        expect(() => getFormatter('not-supported')(1)).toThrow();
      });
    });
  });
});
