<script>
import { n__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { LIST_INTRO_TEXT, LIST_TITLE_TEXT } from '../constants';

export default {
  name: 'PackageTitle',
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
    showPackageCount() {
      return Number.isInteger(this.count);
    },
    packageAmountText() {
      return n__(`%d Package`, `%d Packages`, this.count);
    },
    infoMessages() {
      return [{ text: LIST_INTRO_TEXT, link: this.helpUrl }];
    },
  },
  i18n: {
    LIST_TITLE_TEXT,
  },
};
</script>

<template>
  <title-area :title="$options.i18n.LIST_TITLE_TEXT" :info-messages="infoMessages">
    <template #metadata-amount>
      <metadata-item v-if="showPackageCount" icon="package" :text="packageAmountText" />
    </template>
  </title-area>
</template>
