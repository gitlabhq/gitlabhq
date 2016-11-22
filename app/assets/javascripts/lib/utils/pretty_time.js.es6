(() => {
  /*
   * TODO: Make these methods more configurable (e.g. parseSeconds timePeriodContstraints,
   * stringifyTime condensed or non-condensed, abbreviateTimelengths)
   * */

  class PrettyTime {

    /*
     * Accepts seconds and returns a timeObject { weeks: #, days: #, hours: #, minutes: # }
     * Seconds can be negative or positive, zero or non-zero.
    */
    static parseSeconds(seconds) {
      const DAYS_PER_WEEK = 5;
      const HOURS_PER_DAY = 8;
      const MINUTES_PER_HOUR = 60;
      const MINUTES_PER_WEEK = DAYS_PER_WEEK * HOURS_PER_DAY * MINUTES_PER_HOUR;
      const MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR;

      const timePeriodConstraints = {
        weeks: MINUTES_PER_WEEK,
        days: MINUTES_PER_DAY,
        hours: MINUTES_PER_HOUR,
        minutes: 1,
      };

      let unorderedMinutes = PrettyTime.secondsToMinutes(seconds);

      return _.mapObject(timePeriodConstraints, (minutesPerPeriod) => {
        const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

        unorderedMinutes -= (periodCount * minutesPerPeriod);

        return periodCount;
      });
    }

    /*
    * Accepts a timeObject and returns a condensed string representation of it
    * (e.g. '1w 2d 3h 1m' or '1h 30m'). Zero value units are not included.
    */

    static stringifyTime(timeObject) {
      const reducedTime = _.reduce(timeObject, (memo, unitValue, unitName) => {
        const isNonZero = !!unitValue;
        return isNonZero ? `${memo} ${unitValue}${unitName.charAt(0)}` : memo;
      }, '').trim();
      return reducedTime.length ? reducedTime : '0m';
    }

    /*
    * Accepts a time string of any size (e.g. '1w 2d 3h 5m' or '1w 2d') and returns
    *  the first non-zero unit/value pair.
    */

    static abbreviateTime(timeStr) {
      return timeStr.split(' ')
        .filter(unitStr => unitStr.charAt(0) !== '0')[0];
    }

    static secondsToMinutes(seconds) {
      return Math.abs(seconds / 60);
    }
  }

  gl.PrettyTime = PrettyTime;
})(window.gl || (window.gl = {}));
