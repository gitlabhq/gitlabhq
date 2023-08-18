<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { stageKeys } from '../constants';
import EmptyState from './commit_sidebar/empty_state.vue';
import CommitFilesList from './commit_sidebar/list.vue';

export default {
  components: {
    CommitFilesList,
    EmptyState,
  },
  computed: {
    ...mapState(['changedFiles', 'stagedFiles', 'lastCommitMsg']),
    ...mapState('commit', ['commitMessage', 'submitCommitLoading']),
    ...mapGetters(['lastOpenedFile', 'someUncommittedChanges', 'activeFile']),
    ...mapGetters('commit', ['discardDraftButtonDisabled']),
    showStageUnstageArea() {
      return Boolean(this.someUncommittedChanges || this.lastCommitMsg);
    },
    activeFileKey() {
      return this.activeFile ? this.activeFile.key : null;
    },
  },
  mounted() {
    this.initialize();
  },
  activated() {
    this.initialize();
  },
  methods: {
    ...mapActions(['openPendingTab', 'updateViewer', 'updateActivityBarView']),
    initialize() {
      const file =
        this.lastOpenedFile && this.lastOpenedFile.type !== 'tree'
          ? this.lastOpenedFile
          : this.activeFile;

      if (!file) return;

      this.openPendingTab({
        file,
        keyPrefix: file.staged ? stageKeys.staged : stageKeys.unstaged,
      })
        .then((changeViewer) => {
          if (changeViewer) {
            this.updateViewer('diff');
          }
        })
        .catch((e) => {
          throw e;
        });
    },
  },
  stageKeys,
};
</script>

<template>
  <div class="multi-file-commit-panel-section">
    <template v-if="showStageUnstageArea">
      <commit-files-list
        :key-prefix="$options.stageKeys.staged"
        :file-list="stagedFiles"
        :active-file-key="activeFileKey"
        :empty-state-text="__('There are no changes')"
        class="is-first"
      />
    </template>
    <empty-state v-else />
  </div>
</template>
