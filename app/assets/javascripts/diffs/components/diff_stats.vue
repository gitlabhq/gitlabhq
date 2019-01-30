<script>
import Icon from '~/vue_shared/components/icon.vue';
import { n__ } from '~/locale';

export default {
  components: { Icon },
  props: {
    addedLines: {
      type: Number,
      required: true,
    },
    removedLines: {
      type: Number,
      required: true,
    },
    diffFilesLength: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    filesText() {
      return n__('File', 'Files', this.diffFilesLength);
    },
    isCompareVersionsHeader() {
      return Boolean(this.diffFilesLength);
    },
  },
};
</script>

<template>
  <div
    class="diff-stats"
    :class="{
      'is-compare-versions-header d-none d-lg-inline-flex': isCompareVersionsHeader,
      'd-inline-flex': !isCompareVersionsHeader,
    }"
  >
    <div v-if="diffFilesLength !== null" class="diff-stats-group">
      <icon name="doc-code" class="diff-stats-icon text-secondary" />
      <strong>{{ diffFilesLength }} {{ filesText }}</strong>
    </div>
    <div class="diff-stats-group cgreen">
      <icon name="file-addition" class="diff-stats-icon" /> <strong>{{ addedLines }}</strong>
    </div>
    <div class="diff-stats-group cred">
      <icon name="file-deletion" class="diff-stats-icon" /> <strong>{{ removedLines }}</strong>
    </div>
  </div>
</template>
