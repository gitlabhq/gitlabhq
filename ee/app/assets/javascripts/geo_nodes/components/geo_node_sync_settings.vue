<script>
  import { s__ } from '~/locale';
  import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
  import tooltip from '~/vue_shared/directives/tooltip';
  import icon from '~/vue_shared/components/icon.vue';

  import { TIME_DIFF } from '../constants';

  export default {
    directives: {
      tooltip,
    },
    components: {
      icon,
    },
    props: {
      syncStatusUnavailable: {
        type: Boolean,
        required: false,
        default: false,
      },
      selectiveSyncType: {
        type: String,
        required: false,
        default: null,
      },
      lastEvent: {
        type: Object,
        required: true,
      },
      cursorLastEvent: {
        type: Object,
        required: true,
      },
    },

    computed: {
      syncType() {
        if (this.selectiveSyncType === null || this.selectiveSyncType === '') {
          return s__('GeoNodes|Full');
        }

        return `${s__('GeoNodes|Selective')} (${this.selectiveSyncType})`;
      },
      eventTimestampEmpty() {
        return this.lastEvent.timeStamp === 0 || this.cursorLastEvent.timeStamp === 0;
      },
      syncLagInSeconds() {
        return this.lagInSeconds(this.lastEvent.timeStamp, this.cursorLastEvent.timeStamp);
      },
      syncStatusIcon() {
        return this.statusIcon(this.syncLagInSeconds);
      },
      syncStatusEventInfo() {
        return this.statusEventInfo(
          this.lastEvent.id,
          this.cursorLastEvent.id,
          this.syncLagInSeconds,
        );
      },
      syncStatusTooltip() {
        return this.statusTooltip(this.syncLagInSeconds);
      },
    },
    methods: {
      lagInSeconds(lastEventTimeStamp, cursorLastEventTimeStamp) {
        let eventDateTime;
        let cursorDateTime;

        if (lastEventTimeStamp && lastEventTimeStamp > 0) {
          eventDateTime = new Date(lastEventTimeStamp * 1000);
        }

        if (cursorLastEventTimeStamp && cursorLastEventTimeStamp > 0) {
          cursorDateTime = new Date(cursorLastEventTimeStamp * 1000);
        }

        return (cursorDateTime - eventDateTime) / 1000;
      },
      statusIcon(syncLag) {
        if (syncLag <= TIME_DIFF.FIVE_MINS) {
          return 'retry';
        } else if (syncLag > TIME_DIFF.FIVE_MINS &&
                  syncLag <= TIME_DIFF.HOUR) {
          return 'warning';
        }
        return 'status_failed';
      },
      statusEventInfo(lastEventId, cursorLastEventId, lagInSeconds) {
        const timeAgoStr = timeIntervalInWords(lagInSeconds);
        const pendingEvents = lastEventId - cursorLastEventId;
        return `${timeAgoStr} (${pendingEvents} events)`;
      },
      statusTooltip(lagInSeconds) {
        if (this.eventTimestampEmpty ||
            lagInSeconds <= TIME_DIFF.FIVE_MINS) {
          return '';
        } else if (lagInSeconds > TIME_DIFF.FIVE_MINS &&
                  lagInSeconds <= TIME_DIFF.HOUR) {
          return s__('GeoNodeSyncStatus|Node is slow, overloaded, or it just recovered after an outage.');
        }
        return s__('GeoNodeSyncStatus|Node is failing or broken.');
      },
    },
  };
</script>

<template>
  <div
    class="node-detail-value"
  >
    <span
      v-if="syncStatusUnavailable"
      class="node-detail-value-bold"
    >
      {{ __('Unknown') }}
    </span>
    <span
      v-else
      v-tooltip
      class="node-sync-settings"
      data-placement="bottom"
      :title="syncStatusTooltip"
    >
      <strong>{{ syncType }}</strong>
      <icon
        name="retry"
        css-classes="sync-status-icon prepend-left-5"
      />
      <span
        v-if="!eventTimestampEmpty"
        class="sync-status-event-info prepend-left-5"
      >
        {{ syncStatusEventInfo }}
      </span>
    </span>
  </div>
</template>
