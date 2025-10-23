import {
  defaultDate,
  serializeParams,
  update15DaysFromNow,
  resetCreatedTime,
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
