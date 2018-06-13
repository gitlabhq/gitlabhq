<script>
import Icon from '../../icon.vue';
import { numberToHumanSize } from '../../../../lib/utils/number_utils';

export default {
  components: {
    Icon,
  },
  props: {
    path: {
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
    fileSizeReadable() {
      return numberToHumanSize(this.fileSize);
    },
    fileName() {
      return this.path.split('/').pop();
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
      <a
        :href="path"
        class="btn btn-default"
        rel="nofollow"
        download
        target="_blank">
        <icon
          :size="16"
          name="download"
          css-classes="float-left append-right-8"
        />
        {{ __('Download') }}
      </a>
    </div>
  </div>
</template>
