<script>
import { n__, s__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

export default {
  name: 'PackageTitle',
  components: {
    MetadataItem,
    TitleArea,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showPackageCount() {
      return Number.isInteger(this.count);
    },
    packageCountText() {
      return n__('PackageRegistry|%d package', 'PackageRegistry|%d packages', this.count);
    },
  },
  i18n: {
    LIST_TITLE_TEXT: s__('PackageRegistry|Package registry'),
  },
};
</script>

<template>
  <title-area :title="$options.i18n.LIST_TITLE_TEXT" :metadata-loading="isLoading">
    <template #metadata-amount>
      <metadata-item v-if="showPackageCount" icon="package" :text="packageCountText" />
    </template>
    <template #right-actions>
      <slot name="settings-link"></slot>
    </template>
  </title-area>
</template>
