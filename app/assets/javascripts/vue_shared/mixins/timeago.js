import { formatDate, getTimeago, timeagoLanguageCode } from '~/lib/utils/datetime_utility';

/**
 * Mixin with time ago methods used in some vue components
 */
export default {
  methods: {
    timeFormatted(time, format) {
      const timeago = getTimeago(format);

      return timeago.format(time, timeagoLanguageCode);
    },

    tooltipTitle(time) {
      return formatDate(time);
    },
  },
};
