import _ from 'lodash';
import {
  getRangeType,
  convertToFixedRange,
  isEqualTimeRanges,
  findTimeRange,
  timeRangeToParams,
  timeRangeFromParams,
} from '~/lib/utils/datetime_range';

const MOCK_NOW = Date.UTC(2020, 0, 23, 20);

const MOCK_NOW_ISO_STRING = new Date(MOCK_NOW).toISOString();

const mockFixedRange = {
  label: 'January 2020',
  start: '2020-01-01T00:00:00.000Z',
  end: '2020-01-31T23:59:00.000Z',
};

const mockAnchoredRange = {
  label: 'First two minutes of 2020',
  anchor: '2020-01-01T00:00:00.000Z',
  direction: 'after',
  duration: {
    seconds: 60 * 2,
  },
};

const mockRollingRange = {
  label: 'Next 2 minutes',
  direction: 'after',
  duration: {
    seconds: 60 * 2,
  },
};

const mockOpenRange = {
  label: '2020 so far',
  anchor: '2020-01-01T00:00:00.000Z',
  direction: 'after',
};

describe('Date time range utils', () => {
  describe('getRangeType', () => {
    it('infers correctly the range type from the input object', () => {
      const rangeTypes = {
        fixed: [{ start: MOCK_NOW_ISO_STRING, end: MOCK_NOW_ISO_STRING }],
        anchored: [{ anchor: MOCK_NOW_ISO_STRING, duration: { seconds: 0 } }],
        rolling: [{ duration: { seconds: 0 } }],
        open: [{ anchor: MOCK_NOW_ISO_STRING }],
        invalid: [
          {},
          { start: MOCK_NOW_ISO_STRING },
          { end: MOCK_NOW_ISO_STRING },
          { start: 'NOT_A_DATE', end: 'NOT_A_DATE' },
          { duration: { seconds: 'NOT_A_NUMBER' } },
          { duration: { seconds: Infinity } },
          { duration: { minutes: 20 } },
          { anchor: MOCK_NOW_ISO_STRING, duration: { seconds: 'NOT_A_NUMBER' } },
          { anchor: MOCK_NOW_ISO_STRING, duration: { seconds: Infinity } },
          { junk: 'exists' },
        ],
      };

      Object.entries(rangeTypes).forEach(([type, examples]) => {
        examples.forEach((example) => expect(getRangeType(example)).toEqual(type));
      });
    });
  });

  describe('convertToFixedRange', () => {
    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => MOCK_NOW);
    });

    afterEach(() => {
      Date.now.mockRestore();
    });

    describe('When a fixed range is input', () => {
      it('converts a fixed range to an equal fixed range', () => {
        expect(convertToFixedRange(mockFixedRange)).toEqual({
          start: mockFixedRange.start,
          end: mockFixedRange.end,
        });
      });

      it('throws an error when fixed range does not contain an end time', () => {
        const aFixedRangeMissingEnd = _.omit(mockFixedRange, 'end');

        expect(() => convertToFixedRange(aFixedRangeMissingEnd)).toThrow();
      });

      it('throws an error when fixed range does not contain a start time', () => {
        const aFixedRangeMissingStart = _.omit(mockFixedRange, 'start');

        expect(() => convertToFixedRange(aFixedRangeMissingStart)).toThrow();
      });

      it('throws an error when the dates cannot be parsed', () => {
        const wrongStart = { ...mockFixedRange, start: 'I_CANNOT_BE_PARSED' };
        const wrongEnd = { ...mockFixedRange, end: 'I_CANNOT_BE_PARSED' };

        expect(() => convertToFixedRange(wrongStart)).toThrow();
        expect(() => convertToFixedRange(wrongEnd)).toThrow();
      });
    });

    describe('When an anchored range is input', () => {
      it('converts to a fixed range', () => {
        expect(convertToFixedRange(mockAnchoredRange)).toEqual({
          start: '2020-01-01T00:00:00.000Z',
          end: '2020-01-01T00:02:00.000Z',
        });
      });

      it('converts to a fixed range with a `before` direction', () => {
        expect(convertToFixedRange({ ...mockAnchoredRange, direction: 'before' })).toEqual({
          start: '2019-12-31T23:58:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('converts to a fixed range without an explicit direction, defaulting to `before`', () => {
        const defaultDirectionRange = _.omit(mockAnchoredRange, 'direction');

        expect(convertToFixedRange(defaultDirectionRange)).toEqual({
          start: '2019-12-31T23:58:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = { ...mockAnchoredRange, anchor: 'I_CANNOT_BE_PARSED' };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when a rolling range is input', () => {
      it('converts to a fixed range', () => {
        expect(convertToFixedRange(mockRollingRange)).toEqual({
          start: '2020-01-23T20:00:00.000Z',
          end: '2020-01-23T20:02:00.000Z',
        });
      });

      it('converts to a fixed range with an implicit `before` direction', () => {
        const noDirection = _.omit(mockRollingRange, 'direction');

        expect(convertToFixedRange(noDirection)).toEqual({
          start: '2020-01-23T19:58:00.000Z',
          end: '2020-01-23T20:00:00.000Z',
        });
      });

      it('throws an error when the duration is not in the right format', () => {
        const wrongDuration = { ...mockRollingRange, duration: { minutes: 20 } };

        expect(() => convertToFixedRange(wrongDuration)).toThrow();
      });

      it('throws an error when the anchor is not valid', () => {
        const wrongAnchor = { ...mockRollingRange, anchor: 'CAN_T_PARSE_THIS' };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when an open range is input', () => {
      it('converts to a fixed range with an `after` direction', () => {
        expect(convertToFixedRange(mockOpenRange)).toEqual({
          start: '2020-01-01T00:00:00.000Z',
          end: '2020-01-23T20:00:00.000Z',
        });
      });

      it('converts to a fixed range with the explicit `before` direction', () => {
        const beforeOpenRange = { ...mockOpenRange, direction: 'before' };

        expect(convertToFixedRange(beforeOpenRange)).toEqual({
          start: '1970-01-01T00:00:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('converts to a fixed range with the implicit `before` direction', () => {
        const noDirectionOpenRange = _.omit(mockOpenRange, 'direction');

        expect(convertToFixedRange(noDirectionOpenRange)).toEqual({
          start: '1970-01-01T00:00:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = { ...mockOpenRange, anchor: 'CAN_T_PARSE_THIS' };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });
  });

  describe('isEqualTimeRanges', () => {
    it('equal only compares relevant properies', () => {
      expect(
        isEqualTimeRanges(
          {
            ...mockFixedRange,
            label: 'A label',
            default: true,
          },
          {
            ...mockFixedRange,
            label: 'Another label',
            default: false,
            anotherKey: 'anotherValue',
          },
        ),
      ).toBe(true);

      expect(
        isEqualTimeRanges(
          {
            ...mockAnchoredRange,
            label: 'A label',
            default: true,
          },
          {
            ...mockAnchoredRange,
            anotherKey: 'anotherValue',
          },
        ),
      ).toBe(true);
    });
  });

  describe('findTimeRange', () => {
    const timeRanges = [
      {
        label: 'Before 2020',
        anchor: '2020-01-01T00:00:00.000Z',
      },
      {
        label: 'Last 30 minutes',
        duration: { seconds: 60 * 30 },
      },
      {
        label: 'In 2019',
        start: '2019-01-01T00:00:00.000Z',
        end: '2019-12-31T12:59:59.999Z',
      },
      {
        label: 'Next 2 minutes',
        direction: 'after',
        duration: {
          seconds: 60 * 2,
        },
      },
    ];

    it('finds a time range', () => {
      const tr0 = {
        anchor: '2020-01-01T00:00:00.000Z',
      };
      expect(findTimeRange(tr0, timeRanges)).toBe(timeRanges[0]);

      const tr1 = {
        duration: { seconds: 60 * 30 },
      };
      expect(findTimeRange(tr1, timeRanges)).toBe(timeRanges[1]);

      const tr1Direction = {
        direction: 'before',
        duration: {
          seconds: 60 * 30,
        },
      };
      expect(findTimeRange(tr1Direction, timeRanges)).toBe(timeRanges[1]);

      const tr2 = {
        someOtherLabel: 'Added arbitrarily',
        start: '2019-01-01T00:00:00.000Z',
        end: '2019-12-31T12:59:59.999Z',
      };
      expect(findTimeRange(tr2, timeRanges)).toBe(timeRanges[2]);

      const tr3 = {
        direction: 'after',
        duration: {
          seconds: 60 * 2,
        },
      };
      expect(findTimeRange(tr3, timeRanges)).toBe(timeRanges[3]);
    });

    it('doesnot finds a missing time range', () => {
      const nonExistant = {
        direction: 'before',
        duration: {
          seconds: 200,
        },
      };
      expect(findTimeRange(nonExistant, timeRanges)).toBeUndefined();
    });
  });

  describe('conversion to/from params', () => {
    const mockFixedParams = {
      start: '2020-01-01T00:00:00.000Z',
      end: '2020-01-31T23:59:00.000Z',
    };

    const mockAnchoredParams = {
      anchor: '2020-01-01T00:00:00.000Z',
      direction: 'after',
      duration_seconds: '120',
    };

    const mockRollingParams = {
      direction: 'after',
      duration_seconds: '120',
    };

    describe('timeRangeToParams', () => {
      it('converts fixed ranges to params', () => {
        expect(timeRangeToParams(mockFixedRange)).toEqual(mockFixedParams);
      });

      it('converts anchored ranges to params', () => {
        expect(timeRangeToParams(mockAnchoredRange)).toEqual(mockAnchoredParams);
      });

      it('converts rolling ranges to params', () => {
        expect(timeRangeToParams(mockRollingRange)).toEqual(mockRollingParams);
      });
    });

    describe('timeRangeFromParams', () => {
      it('converts fixed ranges from params', () => {
        const params = { ...mockFixedParams, other_param: 'other_value' };
        const expectedRange = _.omit(mockFixedRange, 'label');

        expect(timeRangeFromParams(params)).toEqual(expectedRange);
      });

      it('converts anchored ranges to params', () => {
        const expectedRange = _.omit(mockRollingRange, 'label');

        expect(timeRangeFromParams(mockRollingParams)).toEqual(expectedRange);
      });

      it('converts rolling ranges from params', () => {
        const params = { ...mockRollingParams, other_param: 'other_value' };
        const expectedRange = _.omit(mockRollingRange, 'label');

        expect(timeRangeFromParams(params)).toEqual(expectedRange);
      });

      it('converts rolling ranges from params with a default direction', () => {
        const params = {
          ...mockRollingParams,
          direction: 'before',
          other_param: 'other_value',
        };
        const expectedRange = _.omit(mockRollingRange, 'label', 'direction');

        expect(timeRangeFromParams(params)).toEqual(expectedRange);
      });

      it('converts to null when for no relevant params', () => {
        const range = {
          useless_param_1: 'value1',
          useless_param_2: 'value2',
        };

        expect(timeRangeFromParams(range)).toBe(null);
      });
    });
  });
});
