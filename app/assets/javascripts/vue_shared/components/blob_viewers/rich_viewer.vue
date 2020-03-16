<script>
import ViewerMixin from './mixins';
import { handleBlobRichViewer } from '~/blob/viewer';

export default {
  mixins: [ViewerMixin],
  mounted() {
    handleBlobRichViewer(this.$refs.content, this.type);
  },
};
</script>
<template>
  <div ref="content" v-html="content"></div>
</template>
