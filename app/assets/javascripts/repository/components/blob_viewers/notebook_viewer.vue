<script>
import { GlLoadingIcon } from '@gitlab/ui';
import notebookLoader from '~/blob/notebook';
import { stripPathTail } from '~/lib/utils/url_utility';

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
    notebookLoader({ el: this.$refs.viewer, relativeRawPath: stripPathTail(this.url) });
  },
};
</script>

<template>
  <div ref="viewer" :data-endpoint="url" data-testid="notebook">
    <gl-loading-icon class="gl-my-4" size="lg" />
  </div>
</template>
