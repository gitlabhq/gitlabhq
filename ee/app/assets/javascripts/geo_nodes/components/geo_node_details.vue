<script>
  /* eslint-disable vue/no-side-effects-in-computed-properties */
  import { s__, __ } from '~/locale';
  import { parseSeconds, stringifyTime } from '~/lib/utils/pretty_time';
  import { numberToHumanSize } from '~/lib/utils/number_utils';
  import icon from '~/vue_shared/components/icon.vue';

  import { VALUE_TYPE, CUSTOM_TYPE } from '../constants';

  import geoNodeDetailItem from './geo_node_detail_item.vue';

  export default {
    components: {
      icon,
      geoNodeDetailItem,
    },
    props: {
      node: {
        type: Object,
        required: true,
      },
      nodeDetails: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        showAdvanceItems: false,
        errorMessage: '',
        nodeDetailItems: [
          {
            itemTitle: s__('GeoNodes|Storage config:'),
            itemValue: this.storageShardsStatus(),
            itemValueType: VALUE_TYPE.PLAIN,
            cssClass: this.plainValueCssClass(!this.nodeDetails.storageShardsMatch),
          },
          {
            itemTitle: s__('GeoNodes|Health status:'),
            itemValue: this.nodeHealthStatus(),
            itemValueType: VALUE_TYPE.CUSTOM,
            customType: CUSTOM_TYPE.STATUS,
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
            itemTitle: s__('GeoNodes|Local job artifacts:'),
            itemValue: this.nodeDetails.jobArtifacts,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Local Attachments:'),
            itemValue: this.nodeDetails.attachments,
            itemValueType: VALUE_TYPE.GRAPH,
          },
          {
            itemTitle: s__('GeoNodes|Sync settings:'),
            itemValue: this.syncSettings(),
            itemValueType: VALUE_TYPE.CUSTOM,
            customType: CUSTOM_TYPE.SYNC,
          },
        ],
      };
    },
    computed: {
      hasError() {
        if (!this.nodeDetails.healthy) {
          this.errorMessage = this.nodeDetails.health;
        }
        return !this.nodeDetails.healthy;
      },
      hasVersionMismatch() {
        if (this.nodeDetails.version !== this.nodeDetails.primaryVersion ||
            this.nodeDetails.revision !== this.nodeDetails.primaryRevision) {
          this.errorMessage = s__('GeoNodes|GitLab version does not match the primary node version');
          return true;
        }
        return false;
      },
      versionCssClass() {
        return this.plainValueCssClass(this.hasVersionMismatch);
      },
      advanceButtonIcon() {
        return this.showAdvanceItems ? 'angle-up' : 'angle-down';
      },
      nodeVersion() {
        if (this.nodeDetails.version == null &&
            this.nodeDetails.revision == null) {
          return __('Unknown');
        }
        return `${this.nodeDetails.version} (${this.nodeDetails.revision})`;
      },
      replicationSlotWAL() {
        return numberToHumanSize(this.nodeDetails.replicationSlotWAL);
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
      valueType() {
        return VALUE_TYPE;
      },
      customType() {
        return CUSTOM_TYPE;
      },
    },
    methods: {
      nodeHealthStatus() {
        return this.nodeDetails.healthy ? this.nodeDetails.health : this.nodeDetails.healthStatus;
      },
      storageShardsStatus() {
        if (this.nodeDetails.storageShardsMatch == null) {
          return __('Unknown');
        }
        return this.nodeDetails.storageShardsMatch ? __('OK') : s__('GeoNodes|Does not match the primary storage configuration');
      },
      plainValueCssClass(value) {
        const cssClass = 'node-detail-value-bold';
        return value ? `${cssClass} node-detail-value-error` : cssClass;
      },
      syncSettings() {
        return {
          syncStatusUnavailable: this.nodeDetails.syncStatusUnavailable,
          selectiveSyncType: this.nodeDetails.selectiveSyncType,
          lastEvent: this.nodeDetails.lastEvent,
          cursorLastEvent: this.nodeDetails.cursorLastEvent,
        };
      },
      onClickShowAdvance() {
        this.showAdvanceItems = !this.showAdvanceItems;
      },
    },
  };
</script>

<template>
  <div class="row">
    <ul class="col-md-8 list-unstyled node-details-list">
      <geo-node-detail-item
        :item-title="s__('GeoNodes|GitLab version:')"
        :css-class="versionCssClass"
        :item-value="nodeVersion"
        :item-value-type="valueType.PLAIN"
      />
      <template v-if="!node.primary">
        <geo-node-detail-item
          v-for="(nodeDetailItem, index) in nodeDetailItems"
          :key="index"
          :css-class="nodeDetailItem.cssClass"
          :item-title="nodeDetailItem.itemTitle"
          :item-value="nodeDetailItem.itemValue"
          :item-value-type="nodeDetailItem.itemValueType"
          :custom-type="nodeDetailItem.customType"
        />
      </template>
      <li class="prepend-top-5 node-detail-item">
        <button
          class="btn-link btn-show-advanced"
          type="button"
          @click="onClickShowAdvance"
        >
          <span>{{ __('Advanced') }}</span>
          <icon
            :size="12"
            :name="advanceButtonIcon"
          />
        </button>
      </li>
      <template v-if="showAdvanceItems">
        <template v-if="node.primary">
          <geo-node-detail-item
            v-if="nodeDetails.repositoryVerificationEnabled"
            :item-title="s__('GeoNodes|Repositories checksummed:')"
            :success-label="s__('GeoNodes|Checksummed')"
            :neutral-label="s__('GeoNodes|Not checksummed')"
            :failure-label="s__('GeoNodes|Failed')"
            :item-value="nodeDetails.verifiedRepositories"
            :item-value-type="valueType.GRAPH"
          />
          <geo-node-detail-item
            v-if="nodeDetails.repositoryVerificationEnabled"
            :item-title="s__('GeoNodes|Wikis checksummed:')"
            :success-label="s__('GeoNodes|Checksummed')"
            :neutral-label="s__('GeoNodes|Not checksummed')"
            :failure-label="s__('GeoNodes|Failed')"
            :item-value="nodeDetails.verifiedWikis"
            :item-value-type="valueType.GRAPH"
          />
          <geo-node-detail-item
            :item-title="s__('GeoNodes|Replication slots:')"
            :success-label="s__('GeoNodes|Used slots')"
            :neutral-label="s__('GeoNodes|Unused slots')"
            :item-value="nodeDetails.replicationSlots"
            :item-value-type="valueType.GRAPH"
          />
          <geo-node-detail-item
            v-if="nodeDetails.replicationSlots.totalCount"
            css-class="node-detail-value-bold"
            :item-title="s__('GeoNodes|Replication slot WAL:')"
            :item-value="replicationSlotWAL"
            :item-value-type="valueType.PLAIN"
          />
        </template>
        <template v-else>
          <geo-node-detail-item
            v-if="nodeDetails.repositoryVerificationEnabled"
            :item-title="s__('GeoNodes|Repository checksums verified:')"
            :success-label="s__('GeoNodes|Verified')"
            :neutral-label="s__('GeoNodes|Unverified')"
            :failure-label="s__('GeoNodes|Failed')"
            :item-value="nodeDetails.verifiedRepositories"
            :item-value-type="valueType.GRAPH"
          />
          <geo-node-detail-item
            v-if="nodeDetails.repositoryVerificationEnabled"
            :item-title="s__('GeoNodes|Wiki checksums verified:')"
            :success-label="s__('GeoNodes|Verified')"
            :neutral-label="s__('GeoNodes|Unverified')"
            :failure-label="s__('GeoNodes|Failed')"
            :item-value="nodeDetails.verifiedWikis"
            :item-value-type="valueType.GRAPH"
          />
          <geo-node-detail-item
            css-class="node-detail-value-bold"
            :item-title="s__('GeoNodes|Database replication lag:')"
            :item-value="dbReplicationLag"
            :item-value-type="valueType.PLAIN"
          />
          <geo-node-detail-item
            :item-title="s__('GeoNodes|Last event ID seen from primary:')"
            :item-value="lastEventStatus"
            :item-value-type="valueType.CUSTOM"
            :custom-type="customType.EVENT"
          />
          <geo-node-detail-item
            :item-title="s__('GeoNodes|Last event ID processed by cursor:')"
            :item-value="cursorLastEventStatus"
            :item-value-type="valueType.CUSTOM"
            :custom-type="customType.EVENT"
          />
        </template>
      </template>
    </ul>
    <div
      v-if="hasError || hasVersionMismatch"
      class="col-md-12 prepend-top-10"
    >
      <p class="health-message">
        {{ errorMessage }}
      </p>
    </div>
  </div>
</template>
