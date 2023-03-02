import { getVisibleCalendarPeriod } from '~/profile/utils';
import { CALENDAR_PERIOD_12_MONTHS, CALENDAR_PERIOD_6_MONTHS } from '~/profile/constants';

describe('getVisibleCalendarPeriod', () => {
  it.each`
    width   | expected
    ${1000} | ${CALENDAR_PERIOD_12_MONTHS}
    ${900}  | ${CALENDAR_PERIOD_6_MONTHS}
  `('returns $expected when container width is $width', ({ width, expected }) => {
    const container = document.createElement('div');
    jest.spyOn(container, 'getBoundingClientRect').mockReturnValueOnce({ width });

    expect(getVisibleCalendarPeriod(container)).toBe(expected);
  });
});
