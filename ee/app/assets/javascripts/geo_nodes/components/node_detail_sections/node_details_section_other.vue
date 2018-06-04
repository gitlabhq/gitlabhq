<script>
  import { s__, __ } from '~/locale';
  import { numberToHumanSize } from '~/lib/utils/number_utils';

  import { VALUE_TYPE } from '../../constants';

  import DetailsSectionMixin from '../../mixins/details_section_mixin';

  import GeoNodeDetailItem from '../geo_node_detail_item.vue';
  import SectionRevealButton from './section_reveal_button.vue';

  export default {
    valueType: VALUE_TYPE,
    components: {
      SectionRevealButton,
      GeoNodeDetailItem,
    },
    mixins: [
      DetailsSectionMixin,
    ],
    props: {
      nodeDetails: {
        type: Object,
        required: true,
      },
      nodeTypePrimary: {
        type: Boolean,
        required: true,
      },
    },
    data() {
      return {
        showSectionItems: false,
      };
    },
    computed: {
      nodeDetailItems() {
        if (this.nodeTypePrimary) {
          // Return primary node detail items
          const primaryNodeDetailItems = [
            {
              itemTitle: s__('GeoNodes|Replication slots'),
              itemValue: this.nodeDetails.replicationSlots,
              itemValueType: VALUE_TYPE.GRAPH,
              successLabel: s__('GeoNodes|Used slots'),
              neutraLabel: s__('GeoNodes|Unused slots'),
            },
          ];

          if (this.nodeDetails.replicationSlots.totalCount) {
            primaryNodeDetailItems.push(
              {
                itemTitle: s__('GeoNodes|Replication slot WAL'),
                itemValue: numberToHumanSize(this.nodeDetails.replicationSlotWAL),
                itemValueType: VALUE_TYPE.PLAIN,
                cssClass: 'node-detail-value-bold',
              },
            );
          }

          return primaryNodeDetailItems;
        }

        // Return secondary node detail items
        return [
          {
            itemTitle: s__('GeoNodes|Storage config'),
            itemValue: this.storageShardsStatus,
            itemValueType: VALUE_TYPE.PLAIN,
            cssClass: this.storageShardsCssClass,
          },
        ];
      },
      storageShardsStatus() {
        if (this.nodeDetails.storageShardsMatch == null) {
          return __('Unknown');
        }
        return this.nodeDetails.storageShardsMatch ? __('OK') : s__('GeoNodes|Does not match the primary storage configuration');
      },
      storageShardsCssClass() {
        const cssClass = 'node-detail-value-bold';
        return !this.nodeDetails.storageShardsMatch ? `${cssClass} node-detail-value-error` : cssClass;
      },
    },
    methods: {
      handleSectionToggle(toggleState) {
        this.showSectionItems = toggleState;
      },
    },
  };
</script>

<template>
  <div class="row-fluid clearfix node-detail-section other-section">
    <div class="col-md-12">
      <section-reveal-button
        :button-title="__('Other information')"
        @toggleButton="handleSectionToggle"
      />
    </div>
    <div
      v-show="showSectionItems"
      class="col-md-6 prepend-left-15 prepend-top-10 section-items-container"
    >
      <geo-node-detail-item
        :item-title="s__('GeoNodes|Storage config')"
        :item-value="storageShardsStatus"
        :item-value-type="$options.valueType.PLAIN"
        :item-value-stale="statusInfoStale"
        :item-value-stale-tooltip="statusInfoStaleMessage"
        :css-class="storageShardsCssClass"
      />
    </div>
  </div>
</template>
