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
    fileName: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    fileSize: {
      type: Number,
      required: false,
      default: 0,
    },
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
  <div class="gl-text-center gl-py-13 gl-bg-gray-50">
    <gl-link :href="filePath" rel="nofollow" :download="fileName" target="_blank">
      <div>
        <gl-icon :size="16" name="download" class="gl-text-gray-900" />
      </div>
      <h4>{{ downloadText }}</h4>
    </gl-link>
  </div>
</template>
