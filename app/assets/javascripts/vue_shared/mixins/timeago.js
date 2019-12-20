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
  },
};
