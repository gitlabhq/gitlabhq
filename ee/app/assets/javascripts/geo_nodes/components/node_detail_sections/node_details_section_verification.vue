<script>
  import { s__ } from '~/locale';

  import { VALUE_TYPE, HELP_INFO_URL } from '../../constants';

  import DetailsSectionMixin from '../../mixins/details_section_mixin';

  import GeoNodeDetailItem from '../geo_node_detail_item.vue';
  import SectionRevealButton from './section_reveal_button.vue';

  export default {
    components: {
      GeoNodeDetailItem,
      SectionRevealButton,
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
    },
    methods: {
      getPrimaryNodeDetailItems() {
        return [
          {
            itemTitle: s__('GeoNodes|Repository checksum progress'),
            itemValue: this.nodeDetails.repositoriesChecksummed,
            itemValueType: VALUE_TYPE.GRAPH,
            successLabel: s__('GeoNodes|Checksummed'),
            neutraLabel: s__('GeoNodes|Not checksummed'),
            failureLabel: s__('GeoNodes|Failed'),
            helpInfo: {
              title: s__('GeoNodes|Repositories checksummed for verification with their counterparts on Secondary nodes'),
              url: HELP_INFO_URL,
              urlText: s__('GeoNodes|Learn more about Repository checksum progress'),
            },
          },
          {
            itemTitle: s__('GeoNodes|Wiki checksum progress'),
            itemValue: this.nodeDetails.wikisChecksummed,
            itemValueType: VALUE_TYPE.GRAPH,
            successLabel: s__('GeoNodes|Checksummed'),
            neutraLabel: s__('GeoNodes|Not checksummed'),
            failureLabel: s__('GeoNodes|Failed'),
            helpInfo: {
              title: s__('GeoNodes|Wikis checksummed for verification with their counterparts on Secondary nodes'),
              url: HELP_INFO_URL,
              urlText: s__('GeoNodes|Learn more about Wiki checksum progress'),
            },
          },
        ];
      },
      getSecondaryNodeDetailItems() {
        return [
          {
            itemTitle: s__('GeoNodes|Repository verification progress'),
            itemValue: this.nodeDetails.verifiedRepositories,
            itemValueType: VALUE_TYPE.GRAPH,
            successLabel: s__('GeoNodes|Verified'),
            neutraLabel: s__('GeoNodes|Unverified'),
            failureLabel: s__('GeoNodes|Failed'),
            helpInfo: {
              title: s__('GeoNodes|Repositories verified with their counterparts on the Primary node'),
              url: HELP_INFO_URL,
              urlText: s__('GeoNodes|Learn more about Repository verification'),
            },
          },
          {
            itemTitle: s__('GeoNodes|Wiki verification progress'),
            itemValue: this.nodeDetails.verifiedWikis,
            itemValueType: VALUE_TYPE.GRAPH,
            successLabel: s__('GeoNodes|Verified'),
            neutraLabel: s__('GeoNodes|Unverified'),
            failureLabel: s__('GeoNodes|Failed'),
            helpInfo: {
              title: s__('GeoNodes|Wikis verified with their counterparts on the Primary node'),
              url: HELP_INFO_URL,
              urlText: s__('GeoNodes|Learn more about Wiki verification'),
            },
          },
        ];
      },
      handleSectionToggle(toggleState) {
        this.showSectionItems = toggleState;
      },
    },
  };
</script>

<template>
  <div class="row-fluid clearfix node-detail-section verification-section">
    <div class="col-md-12">
      <section-reveal-button
        :button-title="__('Verification information')"
        @toggleButton="handleSectionToggle"
      />
    </div>
    <template v-if="showSectionItems">
      <div
        class="col-md-6 prepend-left-15 prepend-top-10 section-items-container"
      >
        <geo-node-detail-item
          v-for="(nodeDetailItem, index) in nodeDetailItems"
          :key="index"
          :css-class="nodeDetailItem.cssClass"
          :item-title="nodeDetailItem.itemTitle"
          :item-value="nodeDetailItem.itemValue"
          :item-value-type="nodeDetailItem.itemValueType"
          :item-value-stale="statusInfoStale"
          :item-value-stale-tooltip="statusInfoStaleMessage"
          :success-label="nodeDetailItem.successLabel"
          :neutral-label="nodeDetailItem.neutraLabel"
          :failure-label="nodeDetailItem.failureLabel"
          :custom-type="nodeDetailItem.customType"
          :help-info="nodeDetailItem.helpInfo"
        />
      </div>
    </template>
  </div>
</template>
