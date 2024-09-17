import {
  getTimeago,
  localeDateFormat,
  newDate,
  timeagoLanguageCode,
} from '~/lib/utils/datetime_utility';

/**
 * Mixin with time ago methods used in some vue components
 */
export default {
  methods: {
    timeFormatted(time, format) {
      const timeago = getTimeago(format);

      return timeago.format(newDate(time), timeagoLanguageCode);
    },

    tooltipTitle(time) {
      return localeDateFormat.asDateTimeFull.format(newDate(time));
    },
  },
};
