<script>
import { GlKeysetPagination, GlSprintf } from '@gitlab/ui';
import { mapState, mapActions } from 'pinia';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { __ } from '~/locale';

export default {
  name: 'FileByFileNavigation',
  components: { GlKeysetPagination, GlSprintf },
  computed: {
    ...mapState(useDiffsView, [
      'singleFileMode',
      'currentFileNumber',
      'hasNextFile',
      'hasPrevFile',
    ]),
    ...mapState(useFileBrowser, ['flatBlobsList']),
    visible() {
      return this.singleFileMode && this.flatBlobsList.length > 1;
    },
    pageInfo() {
      return {
        hasPreviousPage: this.hasPrevFile,
        hasNextPage: this.hasNextFile,
      };
    },
  },
  methods: {
    ...mapActions(useDiffsView, ['goToNextFile', 'goToPrevFile']),
  },
  i18n: {
    fileCount: __('File %{current} of %{total}'),
  },
};
</script>

<template>
  <div v-if="visible" data-testid="file-by-file-navigation" class="gl-grid gl-text-center">
    <gl-keyset-pagination
      class="gl-mx-auto"
      v-bind="pageInfo"
      @prev="goToPrevFile"
      @next="goToNextFile"
    />
    <gl-sprintf :message="$options.i18n.fileCount">
      <template #current>{{ currentFileNumber }}</template>
      <template #total>{{ flatBlobsList.length }}</template>
    </gl-sprintf>
  </div>
</template>
