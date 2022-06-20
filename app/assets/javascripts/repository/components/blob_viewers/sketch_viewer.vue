<script>
import { GlLoadingIcon } from '@gitlab/ui';
import SketchLoader from '~/blob/sketch';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      url: this.blob.rawPath,
    };
  },
  mounted() {
    // eslint-disable-next-line no-new
    new SketchLoader(this.$refs.viewer);
  },
};
</script>

<template>
  <div ref="viewer" class="file-content" :data-endpoint="url" data-testid="sketch">
    <gl-loading-icon class="my-4 js-loading-icon" size="lg" />
  </div>
</template>
