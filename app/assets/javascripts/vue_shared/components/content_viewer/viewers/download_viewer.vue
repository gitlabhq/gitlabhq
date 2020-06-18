<script>
import { GlLink } from '@gitlab/ui';
import Icon from '../../icon.vue';
import { numberToHumanSize } from '../../../../lib/utils/number_utils';

export default {
  components: {
    GlLink,
    Icon,
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
      <p class="prepend-top-10 file-info">
        {{ fileName }}
        <template v-if="fileSize > 0">
          ({{ fileSizeReadable }})
        </template>
      </p>
      <gl-link
        :href="path"
        class="btn btn-default"
        rel="nofollow"
        :download="fileName"
        target="_blank"
      >
        <icon :size="16" name="download" class="float-left gl-mr-3" />
        {{ __('Download') }}
      </gl-link>
    </div>
  </div>
</template>
