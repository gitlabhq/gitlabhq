import {
  defaultDate,
  navigateToQuery,
  serializeParams,
  update15DaysFromNow,
  resetCreatedTime,
  isWithin2Weeks,
  rotationDefaultDate,
} from '~/vue_shared/access_tokens/utils';

// Current date, `new Date()`, for these tests is 2020-07-06
describe('defaultDate', () => {
  describe('when max date is not present', () => {
    it('defaults to 30 days from now', () => {
      expect(defaultDate().getTime()).toBe(new Date('2020-08-05').getTime());
    });
  });

  describe('when max date is present', () => {
    it('defaults to 30 days from now if max date is later', () => {
      const maxDate = new Date('2021-01-01');
      expect(defaultDate(maxDate).getTime()).toBe(new Date('2020-08-05').getTime());
    });

    it('defaults max date if max date is sooner than 30 days', () => {
      const maxDate = new Date('2020-08-01');
      expect(defaultDate(maxDate).getTime()).toBe(new Date('2020-08-01').getTime());
    });
  });
});

describe('rotationDefaultDate', () => {
  const createdAt = '2020-01-01T10:20:30.000Z';

  describe('when the token does not expire', () => {
    it('returns null when there is no max date', () => {
      expect(rotationDefaultDate({ createdAt, expiresAt: null })).toBe(null);
    });

    it('returns the creation default when there is a max date', () => {
      const maxDate = new Date('2021-01-01');

      expect(rotationDefaultDate({ createdAt, expiresAt: null }, { maxDate }).getTime()).toBe(
        new Date('2020-08-05').getTime(),
      );
    });
  });

  describe('when the token expires', () => {
    it('keeps the token lifetime starting today', () => {
      expect(rotationDefaultDate({ createdAt, expiresAt: '2020-01-31' }).getTime()).toBe(
        new Date('2020-08-05').getTime(),
      );
    });

    it('returns the max date when the lifetime ends after it', () => {
      const maxDate = new Date('2020-12-31');

      expect(
        rotationDefaultDate({ createdAt, expiresAt: '2021-01-01' }, { maxDate }).getTime(),
      ).toBe(maxDate.getTime());
    });

    it('returns the min date when the lifetime ends before it', () => {
      const minDate = new Date('2020-07-07');

      expect(
        rotationDefaultDate({ createdAt, expiresAt: '2020-01-01' }, { minDate }).getTime(),
      ).toBe(minDate.getTime());
    });
  });
});

describe('serializeParams', () => {
  it('returns correct params for the fetch', () => {
    expect(
      serializeParams(
        [
          'my token',
          {
            type: 'created',
            value: { data: '2025-01-01', operator: '<' },
          },
          {
            type: 'expires',
            value: { data: '2025-01-02', operator: '<' },
          },
          {
            type: 'last_used',
            value: { data: '2025-01-03', operator: '≥' },
          },
          {
            type: 'state',
            value: { data: 'inactive', operator: '=' },
          },
        ],
        2,
      ),
    ).toMatchObject({
      created_before: '2025-01-01',
      expires_before: '2025-01-02',
      last_used_after: '2025-01-03',
      page: 2,
      search: 'my token',
      state: 'inactive',
    });
  });
});

describe('navigateToQuery', () => {
  const query = { page: 1, sort: 'expires_asc' };
  let router;

  const createRouter = (currentQuery = {}) => ({
    currentRoute: { query: currentQuery },
    push: jest.fn(),
    replace: jest.fn(),
  });

  beforeEach(() => {
    router = createRouter();
  });

  it('pushes the query by default', () => {
    navigateToQuery(router, query);

    expect(router.push).toHaveBeenCalledWith({ query });
    expect(router.replace).not.toHaveBeenCalled();
  });

  it('replaces the query when `replace` is set', () => {
    navigateToQuery(router, query, { replace: true });

    expect(router.replace).toHaveBeenCalledWith({ query });
    expect(router.push).not.toHaveBeenCalled();
  });

  it('does not navigate when the current route already has the same query', () => {
    router = createRouter({ sort: 'expires_asc', page: '1' });
    navigateToQuery(router, query);

    expect(router.push).not.toHaveBeenCalled();
  });

  it('navigates when a query value differs', () => {
    router = createRouter({ page: '2', sort: 'expires_asc' });
    navigateToQuery(router, query);

    expect(router.push).toHaveBeenCalledWith({ query });
  });
});

describe('update2WeekFromNow', () => {
  const param = [
    {
      title: 'dummy',
      tooltipTitle: 'dummy',
      filters: [{ type: 'dummy', value: { data: 'DATE_HOLDER', operator: 'dummy' } }],
    },
  ];

  it('replace `DATE_HOLDER` with date 2 weeks from now', () => {
    expect(update15DaysFromNow(param)).toMatchObject([
      {
        title: 'dummy',
        tooltipTitle: 'dummy',
        filters: [{ type: 'dummy', value: { data: '2020-07-21', operator: 'dummy' } }],
      },
    ]);
  });

  it('use default parameter', () => {
    expect(update15DaysFromNow()).toBeDefined();
  });

  it('returns a clone of the original parameter', () => {
    const result = update15DaysFromNow(param);
    expect(result).not.toBe(param);
    expect(result[0].filters).not.toBe(param[0].filters);
  });
});

describe('resetCreatedTime', () => {
  it('returns a transformed datetime', () => {
    expect(resetCreatedTime('2025-10-13T19:56:59.460Z')).toBe('2025-10-13T00:00:00.000Z');
  });
});

describe('isWithin2Weeks', () => {
  beforeEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: false });
    jest.setSystemTime(new Date('2020-02-10T12:34:56Z'));
  });

  it('returns true when timestamp is within 2 weeks', () => {
    expect(isWithin2Weeks('2020-02-24')).toBe(true);
  });

  it('returns false when timestamp is not within 2 weeks', () => {
    expect(isWithin2Weeks('2020-02-25')).toBe(false);
  });
});
