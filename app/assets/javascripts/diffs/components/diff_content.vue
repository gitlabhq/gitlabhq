<script>
import { mapGetters } from 'vuex';
import InlineDiffView from './inline_diff_view.vue';
import ParallelDiffView from './parallel_diff_view.vue';

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
};
</script>

<template>
  <div class="diff-content">
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
</template>
