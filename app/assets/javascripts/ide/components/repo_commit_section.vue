<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import tooltip from '~/vue_shared/directives/tooltip';
import CommitFilesList from './commit_sidebar/list.vue';
import EmptyState from './commit_sidebar/empty_state.vue';
import { leftSidebarViews, stageKeys } from '../constants';

export default {
  components: {
    CommitFilesList,
    EmptyState,
  },
  directives: {
    tooltip,
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
  watch: {
    someUncommittedChanges() {
      if (!this.someUncommittedChanges) {
        this.updateActivityBarView(leftSidebarViews.edit.name);
      }
    },
  },
  mounted() {
    if (this.lastOpenedFile && this.lastOpenedFile.type !== 'tree') {
      this.openPendingTab({
        file: this.lastOpenedFile,
        keyPrefix: this.lastOpenedFile.staged ? stageKeys.staged : stageKeys.unstaged,
      })
        .then(changeViewer => {
          if (changeViewer) {
            this.updateViewer('diff');
          }
        })
        .catch(e => {
          throw e;
        });
    }
  },
  methods: {
    ...mapActions(['openPendingTab', 'updateViewer', 'updateActivityBarView']),
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
        icon-name="unstaged"
      />
    </template>
    <empty-state v-else />
  </div>
</template>
