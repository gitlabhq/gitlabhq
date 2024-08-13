import { getTimeago, localTimeAgo, timeFor, duration } from '~/lib/utils/datetime/timeago_utility';
import { DATE_ONLY_FORMAT, localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

import '~/commons/bootstrap';

describe('TimeAgo utils', () => {
  describe('getTimeago', () => {
    describe('with User Setting timeDisplayRelative: true', () => {
      beforeEach(() => {
        window.gon = { time_display_relative: true };
      });

      it.each([
        [new Date().toISOString(), 'just now'],
        [new Date().getTime(), 'just now'],
        [new Date(), 'just now'],
        [null, 'just now'],
      ])('formats date `%p` as `%p`', (date, result) => {
        expect(getTimeago().format(date)).toEqual(result);
      });
    });

    describe('with User Setting timeDisplayRelative: false', () => {
      beforeEach(() => {
        window.gon = { time_display_relative: false };
      });

      const defaultFormatExpectations = [
        [new Date().toISOString(), 'Jul 6, 2020, 12:00 AM'],
        [new Date(), 'Jul 6, 2020, 12:00 AM'],
        [new Date().getTime(), 'Jul 6, 2020, 12:00 AM'],
        // Slightly different behaviour when `null` is passed :see_no_evil`
        [null, 'Jan 1, 1970, 12:00 AM'],
      ];

      it.each(defaultFormatExpectations)('formats date `%p` as `%p`', (date, result) => {
        expect(getTimeago().format(date)).toEqual(result);
      });

      describe('with unknown format', () => {
        it.each(defaultFormatExpectations)(
          'uses default format and formats date `%p` as `%p`',
          (date, result) => {
            expect(getTimeago('non_existent').format(date)).toEqual(result);
          },
        );
      });

      describe('with DATE_ONLY_FORMAT', () => {
        it.each([
          [new Date().toISOString(), 'Jul 6, 2020'],
          [new Date(), 'Jul 6, 2020'],
          [new Date().getTime(), 'Jul 6, 2020'],
          [null, 'Jan 1, 1970'],
        ])('formats date `%p` as `%p`', (date, result) => {
          expect(getTimeago(DATE_ONLY_FORMAT).format(date)).toEqual(result);
        });
      });
    });
  });

  describe('timeFor', () => {
    it('returns localize `past due` when in past', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() - 1);

      expect(timeFor(date)).toBe('Past due');
    });

    it('returns localized remaining time when in the future', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);

      // Add a day to prevent a transient error. If date is even 1 second
      // short of a full year, timeFor will return '11 months remaining'
      date.setDate(date.getDate() + 1);

      expect(timeFor(date)).toBe('1 year remaining');
    });
  });

  describe('duration', () => {
    const ONE_DAY = 24 * 60 * 60;

    it.each`
      secs                 | formatted
      ${0}                 | ${'0 seconds'}
      ${30}                | ${'30 seconds'}
      ${59}                | ${'59 seconds'}
      ${60}                | ${'1 minute'}
      ${-60}               | ${'1 minute'}
      ${2 * 60}            | ${'2 minutes'}
      ${60 * 60}           | ${'1 hour'}
      ${2 * 60 * 60}       | ${'2 hours'}
      ${ONE_DAY}           | ${'1 day'}
      ${2 * ONE_DAY}       | ${'2 days'}
      ${7 * ONE_DAY}       | ${'1 week'}
      ${14 * ONE_DAY}      | ${'2 weeks'}
      ${31 * ONE_DAY}      | ${'1 month'}
      ${61 * ONE_DAY}      | ${'2 months'}
      ${365 * ONE_DAY}     | ${'1 year'}
      ${365 * 2 * ONE_DAY} | ${'2 years'}
    `('formats $secs as "$formatted"', ({ secs, formatted }) => {
      const ms = secs * 1000;

      expect(duration(ms)).toBe(formatted);
    });

    // `duration` can be used to format Rails month durations.
    // Ensure formatting for quantities such as `2.months.to_i`
    // based on ActiveSupport::Duration::SECONDS_PER_MONTH.
    // See: https://api.rubyonrails.org/classes/ActiveSupport/Duration.html
    const SECONDS_PER_MONTH = 2629746; // 1.month.to_i

    it.each`
      duration      | secs                     | formatted
      ${'1.month'}  | ${SECONDS_PER_MONTH}     | ${'1 month'}
      ${'2.months'} | ${SECONDS_PER_MONTH * 2} | ${'2 months'}
      ${'3.months'} | ${SECONDS_PER_MONTH * 3} | ${'3 months'}
    `(
      'formats ActiveSupport::Duration of `$duration` ($secs) as "$formatted"',
      ({ secs, formatted }) => {
        const ms = secs * 1000;

        expect(duration(ms)).toBe(formatted);
      },
    );
  });

  describe('localTimeAgo', () => {
    beforeEach(() => {
      document.body.innerHTML =
        '<time title="some time" datetime="2020-02-18T22:22:32Z">1 hour ago</time>';
    });

    describe.each`
      timeDisplayRelative | text
      ${true}             | ${'4 months ago'}
      ${false}            | ${'Feb 18, 2020, 10:22 PM'}
    `(
      `With User Setting timeDisplayRelative: $timeDisplayRelative`,
      ({ timeDisplayRelative, text }) => {
        it.each`
          updateTooltip | title
          ${false}      | ${'some time'}
          ${true}       | ${'February 18, 2020 at 10:22:32 PM GMT'}
        `(
          `has content: '${text}' and tooltip: '$title' with updateTooltip = $updateTooltip`,
          ({ updateTooltip, title }) => {
            window.gon = { time_display_relative: timeDisplayRelative };

            const element = document.querySelector('time');
            localTimeAgo([element], updateTooltip);

            jest.runAllTimers();

            expect(element.getAttribute('title')).toBe(title);
            expect(element.innerText).toBe(text);
          },
        );
      },
    );

    describe('With User Setting Time Format', () => {
      it.each`
        timeDisplayFormat | display      | text
        ${0}              | ${'System'}  | ${'Feb 18, 2020, 10:22 PM'}
        ${1}              | ${'12-hour'} | ${'Feb 18, 2020, 10:22 PM'}
        ${2}              | ${'24-hour'} | ${'Feb 18, 2020, 22:22'}
      `(`'$display' renders as '$text'`, ({ timeDisplayFormat, text }) => {
        localeDateFormat.reset();
        gon.time_display_relative = false;
        gon.time_display_format = timeDisplayFormat;

        const element = document.querySelector('time');
        localTimeAgo([element]);

        jest.runAllTimers();

        expect(element.innerText).toBe(text);
      });
    });
  });
});
