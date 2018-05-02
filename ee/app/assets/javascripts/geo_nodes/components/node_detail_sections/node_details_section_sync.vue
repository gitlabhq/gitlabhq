<script>
  import { s__, __ } from '~/locale';
  import { parseSeconds, stringifyTime } from '~/lib/utils/pretty_time';

  import { VALUE_TYPE, CUSTOM_TYPE } from '../../constants';

  import GeoNodeDetailItem from '../geo_node_detail_item.vue';
  import SectionRevealButton from './section_reveal_button.vue';

  export default {
    components: {
      SectionRevealButton,
      GeoNodeDetailItem,
    },
    props: {
      nodeDetails: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        showSectionItems: false,
        nodeDetailItems: [
          {
            itemTitle: s__('GeoNodes|Sync settings:'),
            itemValue: this.syncSettings(),
            itemValueType: VALUE_TYPE.CUSTOM,
            customType: CUSTOM_TYPE.SYNC,
          },
          {
            itemTitle: s__('GeoNodes|Repositories:'),
            itemValue: this.nodeDetails.repositories,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Wikis:'),
            itemValue: this.nodeDetails.wikis,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Local LFS objects:'),
            itemValue: this.nodeDetails.lfs,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Local attachments:'),
            itemValue: this.nodeDetails.attachments,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Local job artifacts:'),
            itemValue: this.nodeDetails.jobArtifacts,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Data replication lag:'),
            itemValue: this.dbReplicationLag(),
            itemValueType: VALUE_TYPE.PLAIN,
          },
          {
            itemTitle: s__('GeoNodes|Last event ID seen from primary:'),
            itemValue: this.lastEventStatus(),
            itemValueType: VALUE_TYPE.CUSTOM,
            customType: CUSTOM_TYPE.EVENT,
          },
          {
            itemTitle: s__('GeoNodes|Latest event log status:'),
            itemValue: this.cursorLastEventStatus(),
            itemValueType: VALUE_TYPE.CUSTOM,
            customType: CUSTOM_TYPE.EVENT,
            eventTypeLogStatus: true,
          },
        ],
      };
    },
    methods: {
      syncSettings() {
        return {
          syncStatusUnavailable: this.nodeDetails.syncStatusUnavailable,
          selectiveSyncType: this.nodeDetails.selectiveSyncType,
          lastEvent: this.nodeDetails.lastEvent,
          cursorLastEvent: this.nodeDetails.cursorLastEvent,
        };
      },
      dbReplicationLag() {
        // Replication lag can be nil if the secondary isn't actually streaming
        if (this.nodeDetails.dbReplicationLag !== null &&
            this.nodeDetails.dbReplicationLag >= 0) {
          const parsedTime = parseSeconds(this.nodeDetails.dbReplicationLag, {
            hoursPerDay: 24,
            daysPerWeek: 7,
          });

          return stringifyTime(parsedTime);
        }

        return __('Unknown');
      },
      lastEventStatus() {
        return {
          eventId: this.nodeDetails.lastEvent.id,
          eventTimeStamp: this.nodeDetails.lastEvent.timeStamp,
        };
      },
      cursorLastEventStatus() {
        return {
          eventId: this.nodeDetails.cursorLastEvent.id,
          eventTimeStamp: this.nodeDetails.cursorLastEvent.timeStamp,
        };
      },
      handleSectionToggle(toggleState) {
        this.showSectionItems = toggleState;
      },
    },
  };
</script>

<template>
  <div class="row-fluid clearfix node-detail-section sync-section">
    <div class="col-md-12">
      <section-reveal-button
        :button-title="__('Sync information')"
        @toggleButton="handleSectionToggle"
      />
    </div>
    <div
      v-show="showSectionItems"
      class="col-md-6 prepend-left-15 prepend-top-10 section-items-container"
    >
      <geo-node-detail-item
        v-for="(nodeDetailItem, index) in nodeDetailItems"
        :key="index"
        :css-class="nodeDetailItem.cssClass"
        :item-title="nodeDetailItem.itemTitle"
        :item-value="nodeDetailItem.itemValue"
        :item-value-type="nodeDetailItem.itemValueType"
        :custom-type="nodeDetailItem.customType"
        :event-type-log-status="nodeDetailItem.eventTypeLogStatus"
      />
    </div>
  </div>
</template>
