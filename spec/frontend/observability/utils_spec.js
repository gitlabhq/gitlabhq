import { periodToDate } from '~/observability/utils';

describe('periodToDate', () => {
  const realDateNow = Date.now;

  const MOCK_NOW_DATE = new Date('2023-10-09 15:30:00');

  beforeEach(() => {
    global.Date.now = jest.fn().mockReturnValue(MOCK_NOW_DATE);
  });

  afterEach(() => {
    global.Date.now = realDateNow;
  });
  it.each`
    periodLabel      | period   | expectedMinDate
    ${'minutes (m)'} | ${'30m'} | ${new Date('2023-10-09 15:00:00')}
    ${'hours (h)'}   | ${'2h'}  | ${new Date('2023-10-09 13:30:00')}
    ${'days (d)'}    | ${'7d'}  | ${new Date('2023-10-02 15:30:00')}
  `('should return the correct date range for $periodLabel', ({ period, expectedMinDate }) => {
    const result = periodToDate(period);
    expect(result.min).toEqual(expectedMinDate);
    expect(result.max).toEqual(MOCK_NOW_DATE);
  });

  it('should return an empty object if period value is not a positive integer', () => {
    expect(periodToDate('')).toEqual({});
    expect(periodToDate('-5d')).toEqual({});
    expect(periodToDate('invalid')).toEqual({});
  });

  it('should return an empty object if unit is not "m", "h", or "d"', () => {
    expect(periodToDate('2w')).toEqual({});
  });
});
