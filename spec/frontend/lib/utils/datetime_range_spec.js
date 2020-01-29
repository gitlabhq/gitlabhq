import _ from 'lodash';
import { getRangeType, convertToFixedRange } from '~/lib/utils/datetime_range';

const MOCK_NOW = Date.UTC(2020, 0, 23, 20);

const MOCK_NOW_ISO_STRING = new Date(MOCK_NOW).toISOString();

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
        examples.forEach(example => expect(getRangeType(example)).toEqual(type));
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
      const defaultFixedRange = {
        start: '2020-01-01T00:00:00.000Z',
        end: '2020-01-31T23:59:00.000Z',
        label: 'January 2020',
      };

      const mockFixedRange = params => ({ ...defaultFixedRange, ...params });

      it('converts a fixed range to an equal fixed range', () => {
        const aFixedRange = mockFixedRange();

        expect(convertToFixedRange(aFixedRange)).toEqual({
          start: defaultFixedRange.start,
          end: defaultFixedRange.end,
        });
      });

      it('throws an error when fixed range does not contain an end time', () => {
        const aFixedRangeMissingEnd = _.omit(mockFixedRange(), 'end');

        expect(() => convertToFixedRange(aFixedRangeMissingEnd)).toThrow();
      });

      it('throws an error when fixed range does not contain a start time', () => {
        const aFixedRangeMissingStart = _.omit(mockFixedRange(), 'start');

        expect(() => convertToFixedRange(aFixedRangeMissingStart)).toThrow();
      });

      it('throws an error when the dates cannot be parsed', () => {
        const wrongStart = mockFixedRange({ start: 'I_CANNOT_BE_PARSED' });
        const wrongEnd = mockFixedRange({ end: 'I_CANNOT_BE_PARSED' });

        expect(() => convertToFixedRange(wrongStart)).toThrow();
        expect(() => convertToFixedRange(wrongEnd)).toThrow();
      });
    });

    describe('When an anchored range is input', () => {
      const defaultAnchoredRange = {
        anchor: '2020-01-01T00:00:00.000Z',
        direction: 'after',
        duration: {
          seconds: 60 * 2,
        },
        label: 'First two minutes of 2020',
      };
      const mockAnchoredRange = params => ({ ...defaultAnchoredRange, ...params });

      it('converts to a fixed range', () => {
        const anAnchoredRange = mockAnchoredRange();

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          start: '2020-01-01T00:00:00.000Z',
          end: '2020-01-01T00:02:00.000Z',
        });
      });

      it('converts to a fixed range with a `before` direction', () => {
        const anAnchoredRange = mockAnchoredRange({ direction: 'before' });

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          start: '2019-12-31T23:58:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('converts to a fixed range without an explicit direction, defaulting to `before`', () => {
        const anAnchoredRange = _.omit(mockAnchoredRange(), 'direction');

        expect(convertToFixedRange(anAnchoredRange)).toEqual({
          start: '2019-12-31T23:58:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = mockAnchoredRange({ anchor: 'I_CANNOT_BE_PARSED' });
        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when a rolling range is input', () => {
      it('converts to a fixed range', () => {
        const aRollingRange = {
          direction: 'after',
          duration: {
            seconds: 60 * 2,
          },
          label: 'Next 2 minutes',
        };

        expect(convertToFixedRange(aRollingRange)).toEqual({
          start: '2020-01-23T20:00:00.000Z',
          end: '2020-01-23T20:02:00.000Z',
        });
      });

      it('converts to a fixed range with an implicit `before` direction', () => {
        const aRollingRangeWithNoDirection = {
          duration: {
            seconds: 60 * 2,
          },
          label: 'Last 2 minutes',
        };

        expect(convertToFixedRange(aRollingRangeWithNoDirection)).toEqual({
          start: '2020-01-23T19:58:00.000Z',
          end: '2020-01-23T20:00:00.000Z',
        });
      });

      it('throws an error when the duration is not in the right format', () => {
        const wrongDuration = {
          direction: 'before',
          duration: {
            minutes: 20,
          },
          label: 'Last 20 minutes',
        };

        expect(() => convertToFixedRange(wrongDuration)).toThrow();
      });

      it('throws an error when the anchor is not valid', () => {
        const wrongAnchor = {
          anchor: 'CAN_T_PARSE_THIS',
          direction: 'after',
          label: '2020 so far',
        };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });

    describe('when an open range is input', () => {
      it('converts to a fixed range with an `after` direction', () => {
        const soFar2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          direction: 'after',
          label: '2020 so far',
        };

        expect(convertToFixedRange(soFar2020)).toEqual({
          start: '2020-01-01T00:00:00.000Z',
          end: '2020-01-23T20:00:00.000Z',
        });
      });

      it('converts to a fixed range with the explicit `before` direction', () => {
        const before2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          direction: 'before',
          label: 'Before 2020',
        };

        expect(convertToFixedRange(before2020)).toEqual({
          start: '1970-01-01T00:00:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('converts to a fixed range with the implicit `before` direction', () => {
        const alsoBefore2020 = {
          anchor: '2020-01-01T00:00:00.000Z',
          label: 'Before 2020',
        };

        expect(convertToFixedRange(alsoBefore2020)).toEqual({
          start: '1970-01-01T00:00:00.000Z',
          end: '2020-01-01T00:00:00.000Z',
        });
      });

      it('throws an error when the anchor cannot be parsed', () => {
        const wrongAnchor = {
          anchor: 'CAN_T_PARSE_THIS',
          direction: 'after',
          label: '2020 so far',
        };

        expect(() => convertToFixedRange(wrongAnchor)).toThrow();
      });
    });
  });
});
