<script>
import { mapGetters, mapState } from 'vuex';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';
import { diffModes } from '~/ide/constants';
import InlineDiffView from './inline_diff_view.vue';
import ParallelDiffView from './parallel_diff_view.vue';

export default {
  components: {
    InlineDiffView,
    ParallelDiffView,
    DiffViewer,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      projectPath: state => state.diffs.projectPath,
      endpoint: state => state.diffs.endpoint,
    }),
    ...mapGetters('diffs', ['isInlineView', 'isParallelView']),
    diffMode() {
      const diffModeKey = Object.keys(diffModes).find(key => this.diffFile[`${key}File`]);
      return diffModes[diffModeKey] || diffModes.replaced;
    },
    isTextFile() {
      return this.diffFile.text;
    },
  },
};
</script>

<template>
  <div class="diff-content">
    <div class="diff-viewer">
      <template v-if="isTextFile">
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
      </template>
      <diff-viewer
        v-else
        :diff-mode="diffMode"
        :new-path="diffFile.newPath"
        :new-sha="diffFile.diffRefs.headSha"
        :old-path="diffFile.oldPath"
        :old-sha="diffFile.diffRefs.baseSha"
        :project-path="projectPath"/>
    </div>
  </div>
</template>
