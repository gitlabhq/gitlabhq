import { periodToDate, dateFilterObjToQuery, queryToDateFilterObj } from '~/observability/utils';
import {
  CUSTOM_DATE_RANGE_OPTION,
  DATE_RANGE_QUERY_KEY,
  DATE_RANGE_START_QUERY_KEY,
  DATE_RANGE_END_QUERY_KEY,
} from '~/observability/constants';

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

describe('queryToDateFilterObj', () => {
  it('returns default date range if no query params provided', () => {
    expect(queryToDateFilterObj({})).toEqual({ value: '1h' });
  });

  it('returns query params with provided value', () => {
    expect(
      queryToDateFilterObj({
        [DATE_RANGE_QUERY_KEY]: '7d',
      }),
    ).toEqual({ value: '7d' });
  });

  it('returns custom range if custom params provided', () => {
    const query = {
      [DATE_RANGE_QUERY_KEY]: CUSTOM_DATE_RANGE_OPTION,
      [DATE_RANGE_START_QUERY_KEY]: '2020-01-01T00:00:00.000Z',
      [DATE_RANGE_END_QUERY_KEY]: '2020-01-02T00:00:00.000Z',
    };
    expect(queryToDateFilterObj(query)).toEqual({
      value: CUSTOM_DATE_RANGE_OPTION,
      startDate: new Date('2020-01-01T00:00:00.000Z'),
      endDate: new Date('2020-01-02T00:00:00.000Z'),
    });
  });

  it('returns default range if custom params invalid', () => {
    const query = {
      [DATE_RANGE_QUERY_KEY]: CUSTOM_DATE_RANGE_OPTION,
      [DATE_RANGE_START_QUERY_KEY]: 'invalid',
      [DATE_RANGE_END_QUERY_KEY]: 'invalid',
    };
    expect(queryToDateFilterObj(query)).toEqual({ value: '1h' });
  });
});

describe('dateFilterObjToQuery', () => {
  it('converts a default date filter', () => {
    expect(
      dateFilterObjToQuery({
        value: '7d',
      }),
    ).toEqual({
      [DATE_RANGE_QUERY_KEY]: '7d',
    });
  });

  it('converts custom filter', () => {
    const filter = {
      value: CUSTOM_DATE_RANGE_OPTION,
      startDate: new Date('2020-01-01T00:00:00.000Z'),
      endDate: new Date('2020-01-02T00:00:00.000Z'),
    };
    expect(dateFilterObjToQuery(filter)).toEqual({
      [DATE_RANGE_QUERY_KEY]: CUSTOM_DATE_RANGE_OPTION,
      [DATE_RANGE_START_QUERY_KEY]: '2020-01-01T00:00:00.000Z',
      [DATE_RANGE_END_QUERY_KEY]: '2020-01-02T00:00:00.000Z',
    });
  });

  it('returns empty object if filter is empty', () => {
    expect(dateFilterObjToQuery({})).toEqual({});
  });

  it('returns empty object if filter undefined', () => {
    expect(dateFilterObjToQuery()).toEqual({});
  });
});
