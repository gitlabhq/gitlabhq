import $ from 'jquery';
import { getTimeago, localTimeAgo, timeFor } from '~/lib/utils/datetime/timeago_utility';
import { s__ } from '~/locale';
import '~/commons/bootstrap';

describe('TimeAgo utils', () => {
  let oldGon;

  afterEach(() => {
    window.gon = oldGon;
  });

  beforeEach(() => {
    oldGon = window.gon;
  });

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

      it.each([
        [new Date().toISOString(), 'Jul 6, 2020, 12:00 AM'],
        [new Date(), 'Jul 6, 2020, 12:00 AM'],
        [new Date().getTime(), 'Jul 6, 2020, 12:00 AM'],
        // Slightly different behaviour when `null` is passed :see_no_evil`
        [null, 'Jan 1, 1970, 12:00 AM'],
      ])('formats date `%p` as `%p`', (date, result) => {
        expect(getTimeago().format(date)).toEqual(result);
      });
    });
  });

  describe('timeFor', () => {
    it('returns localize `past due` when in past', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() - 1);

      expect(timeFor(date)).toBe(s__('Timeago|Past due'));
    });

    it('returns localized remaining time when in the future', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);

      // Add a day to prevent a transient error. If date is even 1 second
      // short of a full year, timeFor will return '11 months remaining'
      date.setDate(date.getDate() + 1);

      expect(timeFor(date)).toBe(s__('Timeago|1 year remaining'));
    });
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
          timeagoArg | title
          ${false}   | ${'some time'}
          ${true}    | ${'Feb 18, 2020 10:22pm UTC'}
        `(
          `has content: '${text}' and tooltip: '$title' with timeagoArg = $timeagoArg`,
          ({ timeagoArg, title }) => {
            window.gon = { time_display_relative: timeDisplayRelative };

            const element = document.querySelector('time');
            localTimeAgo($(element), timeagoArg);

            jest.runAllTimers();

            expect(element.getAttribute('title')).toBe(title);
            expect(element.innerText).toBe(text);
          },
        );
      },
    );
  });
});
