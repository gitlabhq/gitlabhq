<script>
  import { s__ } from '~/locale';
  import stackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';

  import { VALUE_TYPE, CUSTOM_TYPE } from '../constants';

  import geoNodeHealthStatus from './geo_node_health_status.vue';
  import geoNodeSyncSettings from './geo_node_sync_settings.vue';
  import geoNodeEventStatus from './geo_node_event_status.vue';

  export default {
    components: {
      stackedProgressBar,
      geoNodeHealthStatus,
      geoNodeSyncSettings,
      geoNodeEventStatus,
    },
    props: {
      itemTitle: {
        type: String,
        required: true,
      },
      cssClass: {
        type: String,
        required: false,
        default: '',
      },
      itemValue: {
        type: [Object, String, Number],
        required: true,
      },
      successLabel: {
        type: String,
        required: false,
        default: s__('GeoNodes|Synced'),
      },
      failureLabel: {
        type: String,
        required: false,
        default: s__('GeoNodes|Failed'),
      },
      neutralLabel: {
        type: String,
        required: false,
        default: s__('GeoNodes|Out of sync'),
      },
      itemValueType: {
        type: String,
        required: true,
      },
      customType: {
        type: String,
        required: false,
        default: '',
      },
    },
    computed: {
      isValueTypePlain() {
        return this.itemValueType === VALUE_TYPE.PLAIN;
      },
      isValueTypeGraph() {
        return this.itemValueType === VALUE_TYPE.GRAPH;
      },
      isValueTypeCustom() {
        return this.itemValueType === VALUE_TYPE.CUSTOM;
      },
      isCustomTypeStatus() {
        return this.customType === CUSTOM_TYPE.STATUS;
      },
      isCustomTypeSync() {
        return this.customType === CUSTOM_TYPE.SYNC;
      },
    },
  };
</script>

<template>
  <li class="row node-detail-item">
    <div class="node-detail-title">
      {{ itemTitle }}
    </div>
    <div
      v-if="isValueTypePlain"
      class="node-detail-value"
      :class="cssClass"
    >
      {{ itemValue }}
    </div>
    <div
      v-if="isValueTypeGraph"
      class="node-detail-value"
    >
      <stacked-progress-bar
        :success-label="successLabel"
        :failure-label="failureLabel"
        :neutral-label="neutralLabel"
        :success-count="itemValue.successCount"
        :failure-count="itemValue.failureCount"
        :total-count="itemValue.totalCount"
      />
    </div>
    <template v-if="isValueTypeCustom">
      <geo-node-health-status
        v-if="isCustomTypeStatus"
        :status="itemValue"
      />
      <geo-node-sync-settings
        v-else-if="isCustomTypeSync"
        :sync-status-unavailable="itemValue.syncStatusUnavailable"
        :selective-sync-type="itemValue.selectiveSyncType"
        :last-event="itemValue.lastEvent"
        :cursor-last-event="itemValue.cursorLastEvent"
      />
      <geo-node-event-status
        v-else
        :event-id="itemValue.eventId"
        :event-time-stamp="itemValue.eventTimeStamp"
      />
    </template>
  </li>
</template>
