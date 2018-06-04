import { s__, sprintf } from '~/locale';
import timeAgoMixin from '~/vue_shared/mixins/timeago';

import { STATUS_DELAY_THRESHOLD_MS } from '../constants';

export default {
  mixins: [timeAgoMixin],
  computed: {
    statusInfoStale() {
      const elapsedMilliseconds = Math.abs(this.nodeDetails.statusCheckTimestamp - Date.now());

      return elapsedMilliseconds > STATUS_DELAY_THRESHOLD_MS;
    },
    statusInfoStaleMessage() {
      return sprintf(s__('GeoNodes|Data is out of date from %{timeago}'), {
        timeago: this.timeFormated(
          this.nodeDetails.statusCheckTimestamp,
        ),
      });
    },
  },
};
