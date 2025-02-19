<script>
import { GlIcon, GlLink, GlTruncate } from '@gitlab/ui';
import { SOURCE_TYPE_GROUP, SOURCE_TYPE_PROJECT, SOURCE_TYPE_FILE } from './constants';

/**
 * A basic formatter for showing the source information of an import
 */
export default {
  name: 'ImportHistoryTableSource',
  components: {
    GlIcon,
    GlLink,
    GlTruncate,
  },
  props: {
    /**
     * Should accept the data that comes form the BulkImport API
     */
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    sourceIconName() {
      switch (this.item.entity_type) {
        case SOURCE_TYPE_PROJECT:
          return 'project';
        case SOURCE_TYPE_FILE:
          return 'project';
        case SOURCE_TYPE_GROUP:
          return 'group';
        default:
          return '';
      }
    },
    isFile() {
      return this.item.entity_type === SOURCE_TYPE_FILE;
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-items-start gl-gap-3 gl-pt-1">
    <gl-icon :name="sourceIconName" class="gl-mt-1 gl-flex-shrink-0" />
    <span v-if="isFile">{{ item.fileName }}</span>
    <gl-link
      v-else
      class="gl-overflow-hidden !gl-text-default hover:gl-underline"
      :href="item.source_full_path"
    >
      <gl-truncate :text="item.source_full_path" position="middle" with-tooltip />
    </gl-link>
  </div>
</template>
