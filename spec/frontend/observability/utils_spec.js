import {
  periodToDate,
  periodToDateRange,
  dateFilterObjToQuery,
  queryToDateFilterObj,
  addTimeToDate,
  formattedTimeFromDate,
  isTracingDateRangeOutOfBounds,
  validatedDateRangeQuery,
  parseGraphQLIssueLinksToRelatedIssues,
  createIssueUrlWithDetails,
} from '~/observability/utils';
import {
  CUSTOM_DATE_RANGE_OPTION,
  DATE_RANGE_QUERY_KEY,
  DATE_RANGE_START_QUERY_KEY,
  DATE_RANGE_END_QUERY_KEY,
  TIMESTAMP_QUERY_KEY,
  TIME_RANGE_OPTIONS_VALUES,
} from '~/observability/constants';

import { mockGraphQlIssueLinks, mockRelatedIssues } from './mock_data';

const MOCK_NOW_DATE = new Date('2023-10-09 15:30:00');
const realDateNow = Date.now;
describe('periodToDate', () => {
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

describe('periodToDateRange', () => {
  beforeEach(() => {
    global.Date.now = jest.fn().mockReturnValue(MOCK_NOW_DATE);
  });

  afterEach(() => {
    global.Date.now = realDateNow;
  });
  it('returns a date range object from period', () => {
    expect(periodToDateRange('30m')).toEqual({
      value: 'custom',
      endDate: new Date('2023-10-09T15:30:00.000Z'),
      startDate: new Date('2023-10-09T15:00:00.000Z'),
    });
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

  it('returns a date range object from a nano timestamp', () => {
    expect(queryToDateFilterObj({ timestamp: '2024-02-19T16:10:15.4433398Z' })).toEqual({
      value: CUSTOM_DATE_RANGE_OPTION,
      startDate: new Date('2024-02-19T16:10:15.443Z'),
      endDate: new Date('2024-02-19T16:10:15.443Z'),
      timestamp: '2024-02-19T16:10:15.4433398Z',
    });
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
  it('converts a filter with timestamp', () => {
    expect(dateFilterObjToQuery({ timestamp: '2024-02-19T16:10:15.4433398Z' })).toEqual({
      [TIMESTAMP_QUERY_KEY]: '2024-02-19T16:10:15.4433398Z',
    });
  });

  it('returns empty object if filter is empty', () => {
    expect(dateFilterObjToQuery({})).toEqual({});
  });

  it('returns empty object if filter undefined', () => {
    expect(dateFilterObjToQuery()).toEqual({});
  });
});

describe('formattedTimeFromDate', () => {
  it('should return an empty string when given an invalid date', () => {
    expect(formattedTimeFromDate(null)).toBe('');
    expect(formattedTimeFromDate(undefined)).toBe('');
    expect(formattedTimeFromDate('invalid')).toBe('');
  });

  it('should return the time in the format "HH:mm:ss"', () => {
    const date = new Date('2023-04-20T12:00:56.789Z');
    expect(formattedTimeFromDate(date)).toBe('12:00:56');
  });

  it('should pad single-digit hours, minutes, and seconds with a leading zero', () => {
    const date = new Date('2023-04-20T07:08:09.012Z');
    expect(formattedTimeFromDate(date)).toBe('07:08:09');
  });
});

describe('addTimeToDate', () => {
  it('should add the time to the date', () => {
    const origDate = new Date('2023-04-01T00:00:00.000Z');
    const timeString = '12:34:56';
    const result = addTimeToDate(timeString, origDate);
    expect(result).toEqual(new Date('2023-04-01T12:34:56.000Z'));
  });

  it('should handle missing seconds', () => {
    const origDate = new Date('2023-04-01T00:00:00.000Z');
    const timeString = '12:34';
    const result = addTimeToDate(timeString, origDate);
    expect(result).toEqual(new Date('2023-04-01T12:34:00.000Z'));
  });

  it('should gracefully handle missing minutes and seconds', () => {
    const origDate = new Date('2023-04-01T00:00:00.000Z');
    const timeString = '12';
    expect(addTimeToDate(timeString, origDate)).toEqual(origDate);
  });

  it('should gracefully handle invalid time strings', () => {
    const origDate = new Date('2023-04-01T00:00:00.000Z');
    const timeString = 'invalid';
    expect(addTimeToDate(timeString, origDate)).toEqual(origDate);
  });

  it('should gracefully handle empty time strings', () => {
    const origDate = new Date('2023-04-01T00:00:00.000Z');
    const timeString = '';
    expect(addTimeToDate(timeString, origDate)).toEqual(origDate);
  });
});

describe('isTracingDateRangeOutOfBounds', () => {
  it('returns false if date range is not custom', () => {
    expect(isTracingDateRangeOutOfBounds({ value: TIME_RANGE_OPTIONS_VALUES.FIVE_MIN })).toBe(
      false,
    );
  });

  it('returns true if custom date range is <= 12h', () => {
    expect(
      isTracingDateRangeOutOfBounds({
        value: CUSTOM_DATE_RANGE_OPTION,
        startDate: new Date('2023-04-01T00:00:00'),
        endDate: new Date('2023-04-01T12:00:00'),
      }),
    ).toBe(false);
  });

  it('returns true if custom date range is > 12h', () => {
    expect(
      isTracingDateRangeOutOfBounds({
        value: CUSTOM_DATE_RANGE_OPTION,
        startDate: new Date('2023-04-01T00:00:00'),
        endDate: new Date('2023-04-01T12:00:01'),
      }),
    ).toBe(true);
  });

  it('returns true if custom date range is in invalid', () => {
    expect(
      isTracingDateRangeOutOfBounds({
        value: CUSTOM_DATE_RANGE_OPTION,
        startDate: 'foo',
        endDate: 'baz',
      }),
    ).toBe(true);
  });
});

describe('validatedDateRangeQuery', () => {
  it('returns the default time range when dateRangeValue is not "custom"', () => {
    const result = validatedDateRangeQuery('1h', '', '');
    expect(result).toEqual({ value: '1h' });
  });

  it('returns the default time range when dateRangeStart or dateRangeEnd is invalid', () => {
    const result = validatedDateRangeQuery('custom', 'invalid', '2023-05-01T00:00:00.000Z');
    expect(result).toEqual({ value: '1h' });
  });

  it('returns the custom date range when dateRangeValue is "custom" and dateRangeStart and dateRangeEnd are valid', () => {
    const startDate = '2023-04-01T00:00:00.000Z';
    const endDate = '2023-05-01T00:00:00.000Z';
    const result = validatedDateRangeQuery('custom', startDate, endDate);
    expect(result).toEqual({
      value: 'custom',
      startDate: new Date(startDate),
      endDate: new Date(endDate),
    });
  });

  it('returns the default date range when dateRangeValue is custom but dateRangeStart or dateRangeEnd are invalid', () => {
    const result = validatedDateRangeQuery('custom', 'foo', 'bar');
    expect(result).toEqual({ value: '1h' });
  });

  it('returns the default time range when dateRangeValue is undefined', () => {
    const result = validatedDateRangeQuery(undefined, '', '');
    expect(result).toEqual({ value: '1h' });
  });
});

describe('createIssueUrlWithDetails', () => {
  it('returns the create issue urls with params', () => {
    expect(
      createIssueUrlWithDetails('http://gdk.test:3443/?foo=bar', { a: 'b', c: 'd' }, 'my_param'),
    ).toBe(
      'http://gdk.test:3443/?foo=bar&my_param=%7B%22a%22%3A%22b%22%2C%22c%22%3A%22d%22%7D&issue%5Bconfidential%5D=true',
    );
  });
});

describe('parseGraphQLIssueLinksToRelatedIssues', () => {
  it('converts a graphql issue object to a related issue', () => {
    expect(parseGraphQLIssueLinksToRelatedIssues(mockGraphQlIssueLinks)).toEqual(mockRelatedIssues);
  });
});
