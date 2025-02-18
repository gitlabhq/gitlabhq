<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { sprintf, __ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      fileName: this.blob.name,
      filePath: this.blob.externalStorageUrl || this.blob.rawPath,
      fileSize: this.blob.rawSize || 0,
    };
  },
  computed: {
    downloadFileSize() {
      return numberToHumanSize(this.fileSize);
    },
    downloadText() {
      if (this.fileSize > 0) {
        return sprintf(__('Download (%{fileSizeReadable})'), {
          fileSizeReadable: this.downloadFileSize,
        });
      }
      return __('Download');
    },
  },
};
</script>

<template>
  <div class="gl-bg-strong gl-py-13 gl-text-center">
    <gl-link :href="filePath" rel="nofollow" :download="fileName" target="_blank">
      <div>
        <gl-icon :size="16" name="download" variant="strong" />
      </div>
      <h4>{{ downloadText }}</h4>
    </gl-link>
  </div>
</template>
