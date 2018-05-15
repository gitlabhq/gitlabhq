<script>
  import { s__, __ } from '~/locale';
  import { numberToHumanSize } from '~/lib/utils/number_utils';

  import { VALUE_TYPE } from '../../constants';

  import GeoNodeDetailItem from '../geo_node_detail_item.vue';
  import SectionRevealButton from './section_reveal_button.vue';

  export default {
    valueType: VALUE_TYPE,
    components: {
      SectionRevealButton,
      GeoNodeDetailItem,
    },
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
        primaryNodeDetailItems: this.getPrimaryNodeDetailItems(),
        secondaryNodeDetailItems: this.getSecondaryNodeDetailItems(),
      };
    },
    computed: {
      nodeDetailItems() {
        return this.nodeTypePrimary ?
          this.getPrimaryNodeDetailItems() :
          this.getSecondaryNodeDetailItems();
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
      getPrimaryNodeDetailItems() {
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
      },
      getSecondaryNodeDetailItems() {
        const secondaryNodeDetailItems = [
          {
            itemTitle: s__('GeoNodes|Storage config'),
            itemValue: this.storageShardsStatus,
            itemValueType: VALUE_TYPE.PLAIN,
            cssClass: this.storageShardsCssClass,
          },
        ];

        return secondaryNodeDetailItems;
      },
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
        v-for="(nodeDetailItem, index) in nodeDetailItems"
        :key="index"
        :css-class="nodeDetailItem.cssClass"
        :item-title="nodeDetailItem.itemTitle"
        :item-value="nodeDetailItem.itemValue"
        :item-value-type="nodeDetailItem.itemValueType"
        :success-label="nodeDetailItem.successLabel"
        :neutral-label="nodeDetailItem.neutraLabel"
      />
    </div>
  </div>
</template>
