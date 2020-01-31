<script>
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';
import { SNIPPET_VISIBILITY_PUBLIC } from '../constants';

export default {
  components: {
    BlobEmbeddable,
  },
  props: {
    snippet: {
      type: Object,
      required: true,
    },
  },
  computed: {
    embeddable() {
      return this.snippet.visibilityLevel === SNIPPET_VISIBILITY_PUBLIC;
    },
  },
};
</script>
<template>
  <div>
    <blob-embeddable v-if="embeddable" class="mb-3" :url="snippet.webUrl" />
  </div>
</template>
