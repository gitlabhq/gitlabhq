<script>
import { s__, n__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

export default {
  name: 'InfrastructureTitle',
  components: {
    TitleArea,
    MetadataItem,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: null,
    },
    helpUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasModules() {
      return Number.isInteger(this.count) && this.count > 0;
    },
    moduleAmountText() {
      return n__(`%d Module`, `%d Modules`, this.count);
    },
    infoMessages() {
      if (!this.hasModules) {
        return [];
      }

      return [{ text: this.$options.i18n.LIST_INTRO_TEXT, link: this.helpUrl }];
    },
  },
  i18n: {
    LIST_TITLE_TEXT: s__('InfrastructureRegistry|Terraform Module Registry'),
    LIST_INTRO_TEXT: s__(
      'InfrastructureRegistry|Publish and share your modules. %{docLinkStart}More information%{docLinkEnd}',
    ),
  },
};
</script>

<template>
  <title-area :title="$options.i18n.LIST_TITLE_TEXT" :info-messages="infoMessages">
    <template #metadata-amount>
      <metadata-item v-if="hasModules" icon="infrastructure-registry" :text="moduleAmountText" />
    </template>
  </title-area>
</template>
