<script>
import { mapGetters } from 'vuex';
import InlineDiffView from './inline_diff_view.vue';
import ParallelDiffView from './parallel_diff_view.vue';
import imageDiffHelper from '~/image_diff/helpers/index';

export default {
  components: {
    InlineDiffView,
    ParallelDiffView,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['isInlineView', 'isParallelView']),
  },
  mounted() {
    if (this.diffFile.imageDiffHtml) {
      const canCreateNote = true;
      const renderCommentBadge = true;
      imageDiffHelper.initImageDiff($(this.$el).closest('.file-holder')[0], canCreateNote, renderCommentBadge);
    }
  },
};
</script>

<template>
  <div
    v-if="diffFile.text"
    class="diff-content"
  >
    <div class="diff-viewer">
      <inline-diff-view
        v-if="isInlineView"
        :diff-file="diffFile"
        :diff-lines="diffFile.highlightedDiffLines || []"
      />
      <parallel-diff-view
        v-if="isParallelView"
        :diff-file="diffFile"
        :diff-lines="diffFile.parallelDiffLines || []"
      />
    </div>
  </div>
  <div
    v-else
    v-html="diffFile.imageDiffHtml"
  >
  </div>
</template>
