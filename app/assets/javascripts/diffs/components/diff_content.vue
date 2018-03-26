<script>
import { mapState } from 'vuex';
import inlineDiffView from './inline_diff_view.vue';
import parallelDiffView from './parallel_diff_view.vue';
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '../constants';

export default {
  components: {
    inlineDiffView,
    parallelDiffView,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      diffViewType: state => state.diffs.diffViewType,
    }),
  },
  created() {
    this.INLINE_DIFF_VIEW_TYPE = INLINE_DIFF_VIEW_TYPE;
    this.PARALLEL_DIFF_VIEW_TYPE = PARALLEL_DIFF_VIEW_TYPE;
  },
};
</script>

<template>
  <div class="diff-content">
    <div class="diff-viewer">
      <inline-diff-view
        v-if="diffViewType === INLINE_DIFF_VIEW_TYPE"
        :diff-file="diffFile"
        :diff-lines="diffFile.highlightedDiffLines || []"
      />
      <parallel-diff-view
        v-if="diffViewType === PARALLEL_DIFF_VIEW_TYPE"
        :diff-file="diffFile"
        :diff-lines="diffFile.parallelDiffLines || []"
      />
    </div>
  </div>
</template>
