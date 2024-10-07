<script>
import { GlIcon } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';

export default {
  components: {
    GlIcon,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
    fileSize: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    fileSizeReadable() {
      return numberToHumanSize(this.fileSize);
    },
    fileName() {
      // path could be a base64 uri too, so check if filePath was passed additionally
      return (this.filePath || this.path).split('/').pop();
    },
  },
};
</script>

<template>
  <div class="file-container">
    <div class="file-content">
      <p class="file-info gl-mt-3">
        {{ fileName }}
        <template v-if="fileSize > 0"> ({{ fileSizeReadable }}) </template>
      </p>
      <a :href="path" class="btn btn-default" rel="nofollow" :download="fileName" target="_blank">
        <gl-icon :size="16" name="download" class="float-left gl-mr-3" />
        {{ __('Download') }}
      </a>
    </div>
  </div>
</template>
