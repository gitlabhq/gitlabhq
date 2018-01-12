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
      namespaces: {
        type: Array,
        required: true,
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
        return this.namespaces.length > 0 ? s__('GeoNodes|Selective') : s__('GeoNodes|Full');
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
        if (lagInSeconds <= TIME_DIFF.FIVE_MINS) {
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
      v-tooltip
      class="node-sync-settings inline"
      data-placement="bottom"
      :title="syncStatusTooltip"
    >
      <strong>{{ syncType }}</strong>
      <icon
        name="retry"
        css-classes="sync-status-icon prepend-left-5"
      />
      <span
        class="sync-status-event-info prepend-left-5"
      >
        {{ syncStatusEventInfo }}
      </span>
    </span>
  </div>
</template>
