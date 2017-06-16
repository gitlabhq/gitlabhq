import '../../lib/utils/datetime_utility';

/**
 * Mixin with time ago methods used in some vue components
 */
export default {
  methods: {
    timeFormated(time) {
      const timeago = gl.utils.getTimeago();

      return timeago.format(time);
    },

    tooltipTitle(time) {
      return gl.utils.formatDate(time);
    },
  },
};
