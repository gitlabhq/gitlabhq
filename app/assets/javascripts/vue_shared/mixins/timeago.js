import { formatDate, getTimeago } from '../../lib/utils/datetime_utility';

/**
 * Mixin with time ago methods used in some vue components
 */
export default {
  methods: {
    timeFormatted(time) {
      const timeago = getTimeago();

      return timeago.format(time);
    },

    tooltipTitle(time) {
      return formatDate(time);
    },

    durationTimeFormatted(duration) {
      const date = new Date(duration * 1000);

      let hh = date.getUTCHours();
      let mm = date.getUTCMinutes();
      let ss = date.getSeconds();

      if (hh < 10) {
        hh = `0${hh}`;
      }
      if (mm < 10) {
        mm = `0${mm}`;
      }
      if (ss < 10) {
        ss = `0${ss}`;
      }

      return `${hh}:${mm}:${ss}`;
    },
  },
};
