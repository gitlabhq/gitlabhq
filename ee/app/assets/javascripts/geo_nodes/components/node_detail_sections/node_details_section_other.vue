<script>
  import { s__, __ } from '~/locale';

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
    },
    data() {
      return {
        showSectionItems: false,
      };
    },
    computed: {
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
        :item-title="s__('GeoNodes|Storage config:')"
        :item-value="storageShardsStatus"
        :item-value-type="$options.valueType.PLAIN"
        :css-class="storageShardsCssClass"
      />
    </div>
  </div>
</template>
